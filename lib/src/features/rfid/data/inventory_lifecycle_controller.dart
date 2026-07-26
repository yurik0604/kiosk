import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/reader_status.dart';
import 'rfid_reader_controller.dart';
import 'tag_processing/tag_cart_bridge.dart';
import 'tag_processing/tag_processing_coordinator.dart';

/// Whether inventory is currently meant to be running for the cart.
class InventoryLifecycleState {
  const InventoryLifecycleState({this.active = false, this.armed = false});

  /// The cart is on screen and wants inventory running.
  final bool active;

  /// Inventory couldn't start immediately (reader still connecting) and will
  /// auto-start when the reader becomes ready.
  final bool armed;

  InventoryLifecycleState copyWith({bool? active, bool? armed}) =>
      InventoryLifecycleState(
        active: active ?? this.active,
        armed: armed ?? this.armed,
      );
}

final inventoryLifecycleProvider =
    NotifierProvider<InventoryLifecycleController, InventoryLifecycleState>(
  InventoryLifecycleController.new,
);

/// Drives RFID inventory + the tag→cart bridge around the cart screen's
/// lifetime.
///
/// Call [enter] when the cart becomes visible and [exit] when it's left. The
/// controller — not any widget — owns the actual reader I/O, so start/stop are
/// serialized, idempotent, and resilient to route transitions, idle dialogs,
/// `PopScope`, and hot reload.
///
/// Start policy (as configured): if the reader is ready it starts immediately;
/// if it's still connecting it arms and auto-starts on the connected
/// transition; if it's offline/errored it skips quietly (the cart still works
/// via manual/simulated scans).
class InventoryLifecycleController extends Notifier<InventoryLifecycleState> {
  static final _log = AppLogger.instance;

  /// Active subscription that waits for the reader to become startable so we
  /// can auto-start inventory once it connects. Null when not armed.
  ProviderSubscription<ReaderStatus>? _armSub;

  /// Monotonic session counter. Bumped on every [enter]. A deferred [exit] runs
  /// only if it still targets the current session — this guards the leave →
  /// re-enter race where the old screen's (deferred) exit could otherwise land
  /// after the new screen's enter and wrongly stop a just-started inventory.
  int _generation = 0;

  @override
  InventoryLifecycleState build() {
    ref.onDispose(_disarm);
    return const InventoryLifecycleState();
  }

  /// The cart is on screen — begin (or arm) inventory and start bridging tags
  /// into the cart. Idempotent. Returns the session generation the caller must
  /// later pass to [exit].
  int enter() {
    _generation++;
    final gen = _generation;
    if (state.active) return gen;
    state = state.copyWith(active: true);

    // Start observing processed tags immediately; it's a no-op until tags flow.
    ref.read(tagCartBridgeProvider.notifier).start();
    // Touch the coordinator so it's constructed and subscribed to reader events
    // before inventory produces any tags.
    ref.read(tagProcessingCoordinatorProvider);

    final status = ref.read(rfidReaderControllerProvider).status;
    if (status.canStart) {
      _startInventory();
    } else if (status == ReaderStatus.connecting) {
      _arm();
    } else {
      // offline / disconnected / error → skip quietly. If a connect completes
      // later (e.g. retried elsewhere) we still want to pick it up, so arm.
      _arm();
      _log.i('InventoryLifecycle: reader not ready ($status); armed for '
          'auto-start on connect');
    }
    return gen;
  }

  /// The cart was left — stop inventory and stop bridging. Idempotent.
  ///
  /// [generation] is the value returned by the matching [enter]. If the cart
  /// was re-entered before this (deferred) exit ran, [generation] is stale and
  /// the call no-ops, leaving the newer session's inventory running.
  void exit(int generation) {
    if (generation != _generation) {
      _log.i('InventoryLifecycle: stale exit (gen=$generation, '
          'current=$_generation) — ignored');
      return;
    }
    if (!state.active) return;
    _disarm();

    final reader = ref.read(rfidReaderControllerProvider.notifier);
    final status = ref.read(rfidReaderControllerProvider).status;
    if (status.canStop) {
      reader.stopInventory();
    }
    // Drop any buffered reads so they don't leak into the next screen.
    ref.read(tagProcessingCoordinatorProvider.notifier).flushPendingTags();
    ref.read(tagCartBridgeProvider.notifier).stop();

    state = const InventoryLifecycleState();
    _log.i('InventoryLifecycle: exited; inventory stopped');
  }

  void _startInventory() {
    ref.read(rfidReaderControllerProvider.notifier).startInventory();
    if (state.armed) state = state.copyWith(armed: false);
    _log.i('InventoryLifecycle: inventory started');
  }

  /// Watch reader status and start inventory the first time it becomes
  /// startable, as long as the cart is still active.
  void _arm() {
    if (_armSub != null) return;
    state = state.copyWith(armed: true);
    _armSub = ref.listen<ReaderStatus>(
      rfidReaderControllerProvider.select((s) => s.status),
      (_, next) {
        if (!state.active) return;
        if (next.canStart) {
          _disarm();
          _startInventory();
        }
      },
    );
  }

  void _disarm() {
    _armSub?.close();
    _armSub = null;
    if (state.armed) state = state.copyWith(armed: false);
  }
}
