import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../logging/app_logger.dart';

final _log = AppLogger.instance;

/// Captures input from a USB HID barcode scanner (which behaves like a fast
/// keyboard) anywhere in the app — even when no text field is focused — and
/// reports the decoded barcode via [onScan].
///
/// It registers a global [HardwareKeyboard] handler, so it receives key events
/// regardless of which widget (if any) currently holds focus. A physical
/// scanner emits the barcode's characters in a rapid burst (typically well
/// under [_maxInterKeyGap] apart) usually terminated by an Enter key; the
/// inter-key timing tells a scan from a human typing, and a short idle flush
/// commits scanners that send no terminator.
class BarcodeScannerListener extends StatefulWidget {
  const BarcodeScannerListener({
    super.key,
    required this.onScan,
    required this.child,
    this.minLength = 3,
  });

  /// Called with the decoded barcode when a scan completes.
  final ValueChanged<String> onScan;

  /// Minimum number of characters to treat a burst as a real scan.
  final int minLength;

  final Widget child;

  @override
  State<BarcodeScannerListener> createState() => _BarcodeScannerListenerState();
}

class _BarcodeScannerListenerState extends State<BarcodeScannerListener> {
  final StringBuffer _buffer = StringBuffer();
  Duration? _lastEventTime;
  Timer? _idleTimer;

  /// Keys arriving closer than this are treated as part of a scanner burst.
  /// Deliberately generous so slower scanners still register as one scan.
  static const Duration _maxInterKeyGap = Duration(milliseconds: 120);

  /// If no terminator arrives, flush the buffer after this idle period.
  static const Duration _idleFlush = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _idleTimer?.cancel();
    super.dispose();
  }

  void _reset() {
    _buffer.clear();
    _lastEventTime = null;
    _idleTimer?.cancel();
  }

  void _commit() {
    _idleTimer?.cancel();
    final code = _buffer.toString().trim();
    _reset();
    if (code.length >= widget.minLength) {
      _log.d('BarcodeScannerListener: scan="$code"');
      widget.onScan(code);
    }
  }

  /// Global key handler. Returns false so events still propagate normally
  /// (e.g. into a focused text field).
  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;

    final now = event.timeStamp;
    final gap = _lastEventTime == null ? Duration.zero : now - _lastEventTime!;
    if (_lastEventTime != null && gap > _maxInterKeyGap) {
      _reset();
    }
    _lastEventTime = now;

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _commit();
      return false;
    }

    final char = event.character;
    if (char != null && char.isNotEmpty && !_isControlChar(char)) {
      _buffer.write(char);
      _idleTimer?.cancel();
      _idleTimer = Timer(_idleFlush, _commit);
    }
    return false;
  }

  bool _isControlChar(String s) {
    final code = s.codeUnitAt(0);
    return code < 0x20 || code == 0x7f;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
