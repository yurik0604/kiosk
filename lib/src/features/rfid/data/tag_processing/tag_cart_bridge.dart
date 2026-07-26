import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../catalog/data/catalog_repository.dart';
import '../../../session/data/session_controller.dart';
import '../../domain/tag.dart';
import 'tag_processing_coordinator.dart';

/// Diagnostics snapshot for the tag→cart bridge.
class TagCartBridgeState {
  const TagCartBridgeState({
    this.running = false,
    this.matched = 0,
    this.unmatched = 0,
  });

  /// Whether the bridge is currently subscribed to processed tags.
  final bool running;

  /// Number of decoded tags that resolved to a catalog item and were offered
  /// to the cart (subject to per-EPC dedup in the session controller).
  final int matched;

  /// Number of decoded tags whose barcode had no catalog match (ignored).
  final int unmatched;

  TagCartBridgeState copyWith({bool? running, int? matched, int? unmatched}) {
    return TagCartBridgeState(
      running: running ?? this.running,
      matched: matched ?? this.matched,
      unmatched: unmatched ?? this.unmatched,
    );
  }
}

final tagCartBridgeProvider =
    NotifierProvider<TagCartBridge, TagCartBridgeState>(TagCartBridge.new);

/// Bridges the tag-processing pipeline output to the session cart.
///
/// While [start]ed, it subscribes to [TagProcessingCoordinator.processedTags]
/// and, for each decoded [Tag], looks the barcode up in the local catalog and
/// adds a matching (non-bag) item to the cart via
/// [SessionController.addByEpc] — which dedups by EPC, so a tag read many times
/// per second still yields a single line. Tags with no catalog match are
/// ignored and counted for diagnostics.
///
/// Lifecycle is owned by the inventory lifecycle controller (start on entering
/// the cart, stop on leaving) rather than by any widget.
class TagCartBridge extends Notifier<TagCartBridgeState> {
  static final _log = AppLogger.instance;

  StreamSubscription<List<Tag>>? _sub;

  @override
  TagCartBridgeState build() {
    ref.onDispose(() {
      _sub?.cancel();
    });
    return const TagCartBridgeState();
  }

  /// Begin consuming processed tags into the cart. Idempotent.
  void start() {
    if (_sub != null) return;

    // Ensure the coordinator is alive and reset its per-EPC decode cache so a
    // fresh cart visit re-reads cleanly.
    final coordinator = ref.read(tagProcessingCoordinatorProvider.notifier);
    _sub = coordinator.processedTags.listen(_onTags);

    state = state.copyWith(running: true);
    _log.i('TagCartBridge: started');
  }

  /// Stop consuming processed tags. Idempotent.
  void stop() {
    if (_sub == null) return;
    _sub!.cancel();
    _sub = null;
    state = state.copyWith(running: false);
    _log.i('TagCartBridge: stopped '
        '(matched=${state.matched}, unmatched=${state.unmatched})');
  }

  void _onTags(List<Tag> tags) {
    if (tags.isEmpty) return;

    final catalog = ref.read(catalogRepositoryProvider);
    final session = ref.read(sessionControllerProvider.notifier);

    var matched = state.matched;
    var unmatched = state.unmatched;

    for (final tag in tags) {
      final item = catalog.findByBarcode(tag.barcode);
      if (item == null) {
        unmatched++;
        continue;
      }
      // Shopping bags are a deliberate manual choice via the bag picker — never
      // auto-added from a tag read (mirrors CatalogRepository.randomAvailable).
      if (CatalogRepository.isBag(item)) {
        continue;
      }
      matched++;
      // Dedup by EPC lives in the session controller.
      session.addByEpc(tag.uid, item);
    }

    if (matched != state.matched || unmatched != state.unmatched) {
      state = state.copyWith(matched: matched, unmatched: unmatched);
    }
  }
}
