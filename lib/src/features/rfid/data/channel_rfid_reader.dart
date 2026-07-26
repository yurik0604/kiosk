import 'dart:async';

import 'package:flutter/services.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/reader_config.dart';
import '../domain/reader_event.dart';
import '../domain/reader_status.dart';
import 'rfid_reader.dart';

/// Default [RfidReader] implementation backed by the native `kiosk/rfid`
/// MethodChannel + `kiosk/rfid/events` EventChannel.
///
/// All vendor selection happens on the native side: Dart just passes the
/// vendor id in [ReaderConfig] and the native plugin instantiates the matching
/// `VendorDriver`. This keeps Dart 100% vendor-agnostic.
class ChannelRfidReader implements RfidReader {
  ChannelRfidReader({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _method = methodChannel ?? const MethodChannel(_methodChannelName),
        _eventChannel = eventChannel ?? const EventChannel(_eventChannelName) {
    _eventSub = _eventChannel
        .receiveBroadcastStream()
        .map<ReaderEvent>(
          (raw) => ReaderEvent.fromMap(raw as Map),
        )
        .listen(_onEvent, onError: _onStreamError);
  }

  static const _methodChannelName = 'kiosk/rfid';
  static const _eventChannelName = 'kiosk/rfid/events';

  final MethodChannel _method;
  final EventChannel _eventChannel;
  late final StreamSubscription<ReaderEvent> _eventSub;

  final StreamController<ReaderEvent> _events = StreamController.broadcast();

  ReaderStatus _status = ReaderStatus.offline;
  String? _vendorId;

  @override
  String get vendorId => _vendorId ?? 'unknown';

  @override
  ReaderStatus get status => _status;

  @override
  Stream<ReaderEvent> get events => _events.stream;

  void _onEvent(ReaderEvent event) {
    if (event is ReaderStatusEvent) {
      _status = event.status;
    } else if (event is ReaderErrorEvent && event.fatal) {
      _status = ReaderStatus.offline;
    }
    _events.add(event);
  }

  void _onStreamError(Object error, StackTrace st) {
    AppLogger.instance.e('RFID event stream error', error: error, stackTrace: st);
    _events.add(ReaderErrorEvent(message: error.toString(), fatal: true));
    _status = ReaderStatus.offline;
  }

  @override
  Future<void> connect(ReaderConfig config) async {
    _vendorId = config.vendor.id;
    try {
      await _method.invokeMethod<void>('connect', config.toChannelMap());
    } on PlatformException catch (e) {
      AppLogger.instance.e('RFID connect failed: ${e.code} ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _method.invokeMethod<void>('disconnect');
    } on PlatformException catch (e) {
      AppLogger.instance.w('RFID disconnect: ${e.code} ${e.message}');
    }
  }

  @override
  Future<void> cancelConnect() async {
    try {
      await _method.invokeMethod<void>('cancelConnect');
    } on PlatformException catch (e) {
      AppLogger.instance.w('RFID cancelConnect: ${e.code} ${e.message}');
    }
  }

  @override
  Future<void> startInventory() async {
    await _method.invokeMethod<void>('startInventory');
  }

  @override
  Future<void> stopInventory() async {
    await _method.invokeMethod<void>('stopInventory');
  }

  @override
  Future<void> dispose() async {
    await _eventSub.cancel();
    await _events.close();
    try {
      await _method.invokeMethod<void>('dispose');
    } on PlatformException catch (_) {
      // Best-effort cleanup; ignore.
    }
  }
}
