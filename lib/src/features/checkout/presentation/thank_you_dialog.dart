import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';

Future<void> showThankYouDialog({
  required BuildContext context,
  Duration autoClose = const Duration(seconds: 3),
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'thank-you',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (ctx, _, _) => _ThankYouDialog(autoClose: autoClose),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _ThankYouDialog extends StatefulWidget {
  const _ThankYouDialog({required this.autoClose});

  final Duration autoClose;

  @override
  State<_ThankYouDialog> createState() => _ThankYouDialogState();
}

class _ThankYouDialogState extends State<_ThankYouDialog>
    with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final AnimationController _shimmer;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _autoCloseTimer = Timer(widget.autoClose, () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _entry.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  static const Color _heartRed = Color(0xFFE53935);
  static const Color _heartRedDark = Color(0xFFB71C1C);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: KioskTokens.spaceM,
        vertical: KioskTokens.spaceL,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            KioskTokens.spaceXL,
            KioskTokens.spaceXXL,
            KioskTokens.spaceXL,
            KioskTokens.spaceXL,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(KioskTokens.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 40,
                spreadRadius: -4,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 220,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_entry, _shimmer]),
                  builder: (context, _) {
                    final ring = Curves.easeOutCubic
                        .transform((_entry.value * 1.3).clamp(0.0, 1.0));
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        for (var i = 0; i < 3; i++)
                          _Ripple(
                            progress: ((_shimmer.value + i / 3) % 1),
                            color: _heartRed,
                          ),
                        Transform.scale(
                          scale: 0.85 + 0.15 * ring,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _heartRed.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: ring,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [_heartRed, _heartRedDark],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _heartRed.withValues(alpha: 0.50),
                                  blurRadius: 36,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        for (var i = 0; i < 10; i++)
                          _Sparkle(
                            angle: (i / 10) * 2 * math.pi,
                            progress: ring,
                            color: scheme.tertiary,
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: KioskTokens.spaceXL),
              Text(
                l10n.thankYouTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                      letterSpacing: -1.4,
                      fontSize: 80,
                      height: 1.0,
                    ),
              ),
              const SizedBox(height: KioskTokens.spaceM),
              Text(
                l10n.thankYouBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                      fontSize: 30,
                    ),
              ),
              const SizedBox(height: KioskTokens.spaceXL),
              _AutoCloseHint(
                duration: widget.autoClose,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Ripple extends StatelessWidget {
  const _Ripple({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = 120 + 160 * progress;
    final opacity = (1 - progress).clamp(0.0, 1.0) * 0.35;
    return Opacity(
      opacity: opacity,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({
    required this.angle,
    required this.progress,
    required this.color,
  });

  final double angle;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final distance = 90 + 40 * progress;
    final dx = math.cos(angle) * distance;
    final dy = math.sin(angle) * distance;
    final opacity = (1 - progress).clamp(0.0, 1.0);
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _AutoCloseHint extends StatefulWidget {
  const _AutoCloseHint({required this.duration, required this.color});

  final Duration duration;
  final Color color;

  @override
  State<_AutoCloseHint> createState() => _AutoCloseHintState();
}

class _AutoCloseHintState extends State<_AutoCloseHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ticker,
      builder: (context, _) {
        final remaining = (widget.duration.inMilliseconds *
                (1 - _ticker.value) /
                1000)
            .ceil()
            .clamp(0, widget.duration.inSeconds);
        return Text(
          AppLocalizations.of(context).thankYouAutoClose(remaining),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: widget.color,
                fontSize: 20,
              ),
        );
      },
    );
  }
}
