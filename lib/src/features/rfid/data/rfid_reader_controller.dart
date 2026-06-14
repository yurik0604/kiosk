import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/reader_config.dart';
import '../domain/reader_event.dart';
import '../domain/reader_status.dart';
import 'reader_config_repository.dart';
import 'rfid_reader.dart';
import 'rfid_reader_registry.dart';

class RfidReaderState {
  const RfidReaderState({
    required this.status,
    this.config,
    this.lastError,
  });

  factory RfidReaderState.initial() =>
      const RfidReaderState(status: ReaderStatus.offline);

  final ReaderStatus status;
  final ReaderConfig? config;
  final String? lastError;

  RfidReaderState copyWith({
    ReaderStatus? status,
    ReaderConfig? config,
    String? lastError,
    bool clearError = false,
  }) {
    return RfidReaderState(
      status: status ?? this.status,
      config: config ?? this.config,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

final rfidReaderRegistryProvider = Provider<RfidReaderRegistry>(
  (_) => const RfidReaderRegistry(),
);

final rfidReaderControllerProvider =
    NotifierProvider<RfidReaderController, RfidReaderState>(
  RfidReaderController.new,
);

/// Single source of truth for the active reader.
///
/// Owns the [RfidReader] instance, mirrors its status into Riverpod state,
/// and re-broadcasts the raw event stream via [eventsProvider] for screens
/// that need tag-level updates (cart, debug overlays, etc.).
class RfidReaderController extends Notifier<RfidReaderState> {
  RfidReader? _reader;
  StreamSubscription<ReaderEvent>? _eventSub;
  final StreamController<ReaderEvent> _eventBus = StreamController.broadcast();

  Stream<ReaderEvent> get events => _eventBus.stream;

  @override
  RfidReaderState build() {
    ref.onDispose(() async {
      await _eventSub?.cancel();
      await _reader?.dispose();
      await _eventBus.close();
    });
    return RfidReaderState.initial();
  }

  /// Load the persisted config (if any) and connect. Call from app boot.
  Future<void> bootstrap() async {
    final repo = ref.read(readerConfigRepositoryProvider);
    final saved = await repo.load();
    if (saved == null || saved.host.isEmpty) {
      AppLogger.instance.i('RFID: no saved reader config, skipping auto-connect');
      return;
    }
    await applyConfig(saved, connect: true);
  }

  /// Persist [config], reset the active reader, and optionally connect.
  Future<void> applyConfig(ReaderConfig config, {bool connect = true}) async {
    await ref.read(readerConfigRepositoryProvider).save(config);

    await _eventSub?.cancel();
    await _reader?.dispose();

    final reader = ref.read(rfidReaderRegistryProvider).create(config.vendor);
    _reader = reader;
    _eventSub = reader.events.listen(_handleEvent);

    state = state.copyWith(config: config, clearError: true);

    if (connect) {
      await _connectInternal(config);
    }
  }

  Future<void> connect() async {
    final cfg = state.config;
    if (cfg == null) {
      throw StateError('No reader config — call applyConfig first');
    }
    await _connectInternal(cfg);
  }

  Future<void> _connectInternal(ReaderConfig cfg) async {
    state = state.copyWith(status: ReaderStatus.connecting, clearError: true);
    try {
      await _reader!.connect(cfg);
    } catch (e, st) {
      AppLogger.instance.e('RFID connect failed', error: e, stackTrace: st);
      state = state.copyWith(
        status: ReaderStatus.error,
        lastError: e.toString(),
      );
    }
  }

  Future<void> disconnect() async {
    await _reader?.disconnect();
  }

  Future<void> startInventory() => _reader?.startInventory() ?? Future.value();

  Future<void> stopInventory() => _reader?.stopInventory() ?? Future.value();

  void _handleEvent(ReaderEvent event) {
    switch (event) {
      case ReaderStatusEvent(:final status, :final message):
        state = state.copyWith(
          status: status,
          lastError: message != null && status == ReaderStatus.error
              ? message
              : state.lastError,
        );
      case ReaderErrorEvent(:final message, :final fatal):
        state = state.copyWith(
          status: fatal ? ReaderStatus.offline : ReaderStatus.error,
          lastError: message,
        );
      case ReaderTagsEvent():
        // Pass-through; tag consumers subscribe to [events].
        break;
    }
    _eventBus.add(event);
  }
}

/// Broadcast stream of all reader events (status + tags + errors).
final rfidReaderEventsProvider = StreamProvider<ReaderEvent>((ref) {
  final controller = ref.watch(rfidReaderControllerProvider.notifier);
  return controller.events;
});
