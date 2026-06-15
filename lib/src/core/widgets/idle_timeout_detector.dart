import 'dart:async';

import 'package:flutter/widgets.dart';

/// Wraps a subtree and invokes [onTimeout] when no pointer-down event has
/// been observed inside it for [timeout].
///
/// The timer starts when the widget mounts and resets every time a
/// `PointerDownEvent` fires inside the wrapped tree. Tap/scroll handling in
/// child widgets is unaffected — this widget uses [Listener] which observes
/// gestures without competing for them.
///
/// Typical usage for an inactivity cancel:
/// ```dart
/// IdleTimeoutDetector(
///   timeout: const Duration(minutes: 1),
///   onTimeout: () => Navigator.of(context).pop(),
///   child: ...,
/// )
/// ```
class IdleTimeoutDetector extends StatefulWidget {
  const IdleTimeoutDetector({
    super.key,
    required this.child,
    required this.onTimeout,
    required this.timeout,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onTimeout;
  final Duration timeout;

  /// When false, the timer is not started and [onTimeout] never fires.
  /// Useful for temporarily disabling the timeout during a critical async
  /// operation without unwrapping the subtree.
  final bool enabled;

  @override
  State<IdleTimeoutDetector> createState() => _IdleTimeoutDetectorState();
}

class _IdleTimeoutDetectorState extends State<IdleTimeoutDetector> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _restart();
  }

  @override
  void didUpdateWidget(IdleTimeoutDetector old) {
    super.didUpdateWidget(old);
    if (old.timeout != widget.timeout || old.enabled != widget.enabled) {
      if (widget.enabled) {
        _restart();
      } else {
        _timer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _restart() {
    _timer?.cancel();
    _timer = Timer(widget.timeout, () {
      if (!mounted) return;
      widget.onTimeout();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restart(),
      child: widget.child,
    );
  }
}
