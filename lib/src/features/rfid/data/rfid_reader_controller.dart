import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/reader_config.dart';
import '../domain/reader_event.dart';
import '../domain/reader_status.dart';
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

  /// Initialize the reader from the kiosk's server config and connect.
  ///
  /// This is the source of truth for reader settings: the config comes from
  /// `kiosk.rfid_config` on every boot (after login / session-restore), so the
  /// server always wins and overrides any prior runtime state. Local [Save]
  /// changes (see [applyConfig]) are runtime-only and do NOT survive a restart —
  /// the next boot re-initializes from the server here.
  ///
  /// No-op (skips connecting) when the server config has no host, so an
  /// unconfigured kiosk doesn't dial a blank address.
  Future<void> initFromServer(ReaderConfig config) async {
    if (config.host.isEmpty) {
      AppLogger.instance
          .i('RFID: server rfid_config has no host; loading without connect');
      await _swapReader(config);
      return;
    }
    await applyConfig(config, connect: true);
  }

  /// Apply [config] to the active reader for the current runtime only, then
  /// optionally connect.
  ///
  /// This is the [Save]/connect path from the settings screen. It updates the
  /// in-memory state and swaps the active reader, but does NOT persist anywhere:
  /// after a restart the config is re-loaded from the server (see
  /// [initFromServer]), overriding these local changes.
  Future<void> applyConfig(ReaderConfig config, {bool connect = true}) async {
    await _swapReader(config);
    if (connect) {
      await _connectInternal(config);
    }
  }

  /// Tear down the current reader and stand up a fresh one for [config]'s
  /// vendor, mirroring the config into state. Does not connect.
  Future<void> _swapReader(ReaderConfig config) async {
    await _eventSub?.cancel();
    await _reader?.dispose();

    final reader = ref.read(rfidReaderRegistryProvider).create(config.vendor);
    _reader = reader;
    _eventSub = reader.events.listen(_handleEvent);

    state = state.copyWith(config: config, clearError: true);
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

  /// Abort an in-flight connect attempt. Takes effect immediately instead of
  /// waiting out the connect timeout (e.g. after a wrong host/IP was entered).
  Future<void> cancelConnect() async {
    await _reader?.cancelConnect();
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
