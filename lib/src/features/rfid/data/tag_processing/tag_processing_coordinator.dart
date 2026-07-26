import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../group/data/group_controller.dart';
import '../../../group/domain/group_settings.dart';
import '../../domain/reader_event.dart';
import '../../domain/rfid_tag.dart';
import '../../domain/tag.dart';
import '../encoding/barcode_converter.dart';
import '../rfid_reader_controller.dart';
import 'pipeline.dart';
import 'tag_processing_config.dart';

/// Immutable snapshot of the coordinator for the UI.
class TagProcessingState {
  const TagProcessingState({
    this.lastBatch = const [],
    this.totalReceived = 0,
    this.totalProcessed = 0,
    this.droppedDueToBackpressure = 0,
  });

  /// The most recently produced batch of decoded/filtered tags.
  final List<Tag> lastBatch;

  final int totalReceived;
  final int totalProcessed;
  final int droppedDueToBackpressure;

  TagProcessingState copyWith({
    List<Tag>? lastBatch,
    int? totalReceived,
    int? totalProcessed,
    int? droppedDueToBackpressure,
  }) {
    return TagProcessingState(
      lastBatch: lastBatch ?? this.lastBatch,
      totalReceived: totalReceived ?? this.totalReceived,
      totalProcessed: totalProcessed ?? this.totalProcessed,
      droppedDueToBackpressure:
          droppedDueToBackpressure ?? this.droppedDueToBackpressure,
    );
  }
}

final tagProcessingCoordinatorProvider =
    NotifierProvider<TagProcessingCoordinator, TagProcessingState>(
  TagProcessingCoordinator.new,
);

/// Coordinates RFID tag processing for the kiosk.
///
/// This is the kiosk counterpart of the field app's `TagProcessingService`:
/// it owns a [TagProcessingPipeline], feeds it the raw [RfidTag]s carried by
/// the reader's [ReaderTagsEvent]s (with batching / throttling / backpressure),
/// and re-broadcasts the resulting decoded + group-filtered [Tag]s on
/// [processedTags].
///
/// The pipeline's encoding standard and group filter are kept in sync with the
/// kiosk's group settings (`group_settings.encoding_standard`,
/// `barcode_standards`, `customer_prefixes`).
///
/// Scope: this stops at producing decoded/filtered [Tag]s — it does NOT add
/// them to a cart/checkout. Downstream consumers subscribe to [processedTags]
/// (or watch this provider's state).
class TagProcessingCoordinator extends Notifier<TagProcessingState> {
  static final _log = AppLogger.instance;

  final TagProcessingConfig _config = const TagProcessingConfig();
  late final TagProcessingPipeline _pipeline;

  final StreamController<List<Tag>> _processedTagsController =
      StreamController<List<Tag>>.broadcast();

  StreamSubscription<ReaderEvent>? _eventSub;

  Timer? _batchTimer;
  final List<RfidTag> _pendingTags = [];
  DateTime _lastProcessTime = DateTime.now();

  int _totalReceived = 0;
  int _totalProcessed = 0;
  int _droppedDueToBackpressure = 0;

  /// Broadcast stream of decoded + filtered tag batches.
  Stream<List<Tag>> get processedTags => _processedTagsController.stream;

  @override
  TagProcessingState build() {
    _pipeline = TagProcessingPipeline();

    // Initialize + keep encoding standard and group filter in sync with the
    // group settings.
    final initialSettings =
        ref.read(groupControllerProvider).group?.settings;
    _applyGroupSettings(initialSettings);

    ref.listen<GroupSettings?>(
      groupControllerProvider.select((s) => s.group?.settings),
      (previous, next) {
        if (previous != next) {
          _applyGroupSettings(next);
        }
      },
    );

    // Subscribe to the reader's event stream and feed tag events into the
    // pipeline.
    final reader = ref.read(rfidReaderControllerProvider.notifier);
    _eventSub = reader.events.listen(_handleReaderEvent);

    ref.onDispose(() async {
      _batchTimer?.cancel();
      await _eventSub?.cancel();
      await _processedTagsController.close();
    });

    return const TagProcessingState();
  }

  /// Configure the converter factory + pipeline group filter from [settings].
  void _applyGroupSettings(GroupSettings? settings) {
    _pipeline.updateGroupSettings(settings);

    if (settings != null) {
      BarcodeConverterFactory.setCurrentStandard(settings.encodingStandard);
      _log.i('TagProcessingCoordinator: encoding standard = ${settings.encodingStandard}, '
          'barcodeStandards = ${settings.barcodeStandards}, '
          'customerPrefixes = ${settings.customerPrefixes}');
    } else {
      _log.i('TagProcessingCoordinator: no group settings; group filtering disabled');
    }
  }

  void _handleReaderEvent(ReaderEvent event) {
    if (event is ReaderTagsEvent && event.tags.isNotEmpty) {
      _enqueue(event.tags);
    }
  }

  /// Feed raw reads into the coordinator (also usable directly for tests /
  /// simulated readers).
  void processTags(List<RfidTag> rfidTags) {
    if (rfidTags.isNotEmpty) _enqueue(rfidTags);
  }

  /// Handle incoming reads with batching + backpressure.
  void _enqueue(List<RfidTag> rfidTags) {
    if (rfidTags.isEmpty) return;

    _totalReceived += rfidTags.length;

    // Apply backpressure if the queue is too large.
    if (_pendingTags.length + rfidTags.length > _config.maxQueueSize) {
      final toAdd = _config.maxQueueSize - _pendingTags.length;
      if (toAdd > 0) {
        _pendingTags.addAll(rfidTags.take(toAdd));
        _droppedDueToBackpressure += rfidTags.length - toAdd;
        _log.w('TagProcessingCoordinator: dropped ${rfidTags.length - toAdd} tags due to backpressure');
      } else {
        _droppedDueToBackpressure += rfidTags.length;
        _log.w('TagProcessingCoordinator: queue full, dropped all ${rfidTags.length} tags');
        _syncCounters();
        return;
      }
    } else {
      _pendingTags.addAll(rfidTags);
    }

    // Apply throttling to avoid overwhelming downstream.
    final now = DateTime.now();
    if (now.difference(_lastProcessTime) < _config.throttleInterval) {
      _scheduleBatch();
      _syncCounters();
      return;
    }

    // Process immediately if the batch is full, otherwise schedule a timer.
    if (_pendingTags.length >= _config.maxBatchSize) {
      _processPendingBatch();
    } else {
      _scheduleBatch();
    }
    _syncCounters();
  }

  void _scheduleBatch() {
    _batchTimer?.cancel();
    _batchTimer = Timer(_config.batchInterval, _processPendingBatch);
  }

  Future<void> _processPendingBatch() async {
    if (_pendingTags.isEmpty) return;

    _batchTimer?.cancel();
    _lastProcessTime = DateTime.now();

    // Take up to maxBatchSize tags.
    final batchSize = _pendingTags.length > _config.maxBatchSize
        ? _config.maxBatchSize
        : _pendingTags.length;
    final tagsBatch = _pendingTags.take(batchSize).toList();
    _pendingTags.removeRange(0, batchSize);

    try {
      final result = await _pipeline.processBatch(tagsBatch);
      _emitProcessed(result.tags);
    } catch (error) {
      _log.e('TagProcessingCoordinator: pipeline processing failed: $error');
      _emitProcessed(const []);
    }

    // Continue if more tags are pending.
    if (_pendingTags.isNotEmpty) {
      _scheduleBatch();
    }
  }

  void _emitProcessed(List<Tag> tags) {
    _totalProcessed += tags.length;
    if (!_processedTagsController.isClosed) {
      _processedTagsController.add(tags);
    }
    state = state.copyWith(
      lastBatch: tags,
      totalReceived: _totalReceived,
      totalProcessed: _totalProcessed,
      droppedDueToBackpressure: _droppedDueToBackpressure,
    );
  }

  /// Mirror counters into state without emitting a batch.
  void _syncCounters() {
    state = state.copyWith(
      totalReceived: _totalReceived,
      droppedDueToBackpressure: _droppedDueToBackpressure,
    );
  }

  /// Flush pending tags and cancel timers (e.g. when inventory stops).
  void flushPendingTags() {
    final pendingCount = _pendingTags.length;
    _batchTimer?.cancel();
    _batchTimer = null;
    _pendingTags.clear();
    if (pendingCount > 0) {
      _log.i('TagProcessingCoordinator: flushed $pendingCount pending tags on stop');
    }
  }

  /// Clear the decode/dedup caches held by cacheable steps.
  void clearProcessingCaches() {
    _pipeline.clearAllCaches();
  }
}

/// Convenience stream provider for the processed (decoded + filtered) tags.
final processedTagsProvider = StreamProvider<List<Tag>>((ref) {
  final coordinator = ref.watch(tagProcessingCoordinatorProvider.notifier);
  return coordinator.processedTags;
});
