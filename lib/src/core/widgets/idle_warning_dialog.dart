import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Shows the inactivity warning dialog and returns `true` if the user
/// interacted within [countdown] (wants to stay), or `false` if the timer
/// ran out (caller should dismiss / leave the screen).
///
/// The dialog itself is fully reusable — pass a screen-specific [title] and
/// [body] if you want to override the defaults from l10n.
Future<bool> showIdleWarningDialog(
  BuildContext context, {
  Duration countdown = const Duration(seconds: 10),
  String? title,
  String? body,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (_) =>
        _IdleWarningDialog(countdown: countdown, title: title, body: body),
  );
  return result ?? false;
}

class _IdleWarningDialog extends StatefulWidget {
  const _IdleWarningDialog({required this.countdown, this.title, this.body});

  final Duration countdown;
  final String? title;
  final String? body;

  @override
  State<_IdleWarningDialog> createState() => _IdleWarningDialogState();
}

class _IdleWarningDialogState extends State<_IdleWarningDialog>
    with TickerProviderStateMixin {
  late final AnimationController _drain = AnimationController(
    vsync: this,
    duration: widget.countdown,
  );

  // Tick animation runs each second to give the digit a "heartbeat" pulse.
  late final AnimationController _tick = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  Timer? _tickTimer;
  bool _settled = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _drain.forward().whenComplete(_handleTimeout);
    _tick.forward();
    // Tick the digit pulse + a light haptic every second.
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      _tick.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _drain.dispose();
    _tick.dispose();
    super.dispose();
  }

  void _stay() {
    if (_settled) return;
    _settled = true;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(true);
  }

  void _handleTimeout() {
    if (_settled) return;
    _settled = true;
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final totalSeconds = widget.countdown.inSeconds;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: KioskTokens.spaceXL,
        vertical: KioskTokens.spaceL,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KioskTokens.radiusLarge),
      ),
      backgroundColor: scheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            KioskTokens.spaceXL,
            KioskTokens.spaceXL,
            KioskTokens.spaceXL,
            KioskTokens.spaceXL,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: _CountdownVisual(
                  drain: _drain,
                  tick: _tick,
                  totalSeconds: totalSeconds,
                  color: scheme.error,
                  background: scheme.errorContainer,
                ),
              ),
              const SizedBox(height: KioskTokens.spaceL),
              Text(
                widget.title ?? l10n.idleWarningTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: KioskTokens.spaceM),
              Text(
                widget.body ?? l10n.idleWarningBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: KioskTokens.spaceL),
              SizedBox(
                height: KioskTokens.touchTargetLarge,
                child: FilledButton.icon(
                  onPressed: _stay,
                  icon: const Icon(Icons.touch_app_rounded, size: 28),
                  label: Text(
                    l10n.idleWarningCta.toUpperCase(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: FilledButton.styleFrom(foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountdownVisual extends StatelessWidget {
  const _CountdownVisual({
    required this.drain,
    required this.tick,
    required this.totalSeconds,
    required this.color,
    required this.background,
  });

  final Animation<double> drain;
  final Animation<double> tick;
  final int totalSeconds;
  final Color color;
  final Color background;

  static const double _size = 160;
  static const double _coreSize = 120;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: _size,
      height: _size,
      child: AnimatedBuilder(
        animation: Listenable.merge([drain, tick]),
        builder: (context, _) {
          final remaining = (totalSeconds - (drain.value * totalSeconds))
              .ceil()
              .clamp(1, totalSeconds);
          // Pulse the digit briefly each tick (1.0 → 1.1 → 1.0 in 600ms).
          final pulse = 1.0 + (math.sin(tick.value * math.pi) * 0.1);
          return Stack(
            alignment: Alignment.center,
            children: [
              // Background ring (full circle, faded).
              CustomPaint(
                size: const Size(_size, _size),
                painter: _RingPainter(
                  progress: 1.0,
                  color: color.withValues(alpha: 0.15),
                  strokeWidth: 10,
                ),
              ),
              // Draining progress arc — starts full, shrinks counter-clockwise.
              CustomPaint(
                size: const Size(_size, _size),
                painter: _RingPainter(
                  progress: 1.0 - drain.value,
                  color: color,
                  strokeWidth: 10,
                ),
              ),
              // Inner filled circle for visual weight.
              Container(
                width: _coreSize,
                height: _coreSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: background,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 24,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Transform.scale(
                    scale: pulse,
                    child: Text(
                      '$remaining',
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  /// 0 = nothing drawn, 1 = full ring.
  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final rect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    ).deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..color = color;
    // Draw starting at the top, going clockwise.
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
