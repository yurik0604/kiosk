import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/payment_process_controller.dart';
import '../domain/payment_transaction.dart';

Future<bool> showPaymentProcessDialog({
  required BuildContext context,
  required double amount,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'payment-process',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (ctx, _, _) => _PaymentProcessDialog(amount: amount),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
  return result ?? false;
}

class _PaymentProcessDialog extends ConsumerStatefulWidget {
  const _PaymentProcessDialog({required this.amount});

  final double amount;

  @override
  ConsumerState<_PaymentProcessDialog> createState() =>
      _PaymentProcessDialogState();
}

class _PaymentProcessDialogState extends ConsumerState<_PaymentProcessDialog> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_started && mounted) {
        _started = true;
        ref
            .read(paymentProcessControllerProvider.notifier)
            .chargeCard(widget.amount);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final txn = ref.watch(paymentProcessControllerProvider);
    final l10n = AppLocalizations.of(context);
    final fmt = NumberFormat.simpleCurrency(
      locale: Localizations.localeOf(context).toString(),
      name: 'ILS',
    );

    ref.listen<PaymentTransaction>(paymentProcessControllerProvider,
        (prev, next) {
      if (prev?.status != PaymentTransactionStatus.approved &&
          next.status == PaymentTransactionStatus.approved) {
        HapticFeedback.mediumImpact();
      }
      if (prev?.status != PaymentTransactionStatus.completed &&
          next.status == PaymentTransactionStatus.completed) {
        if (mounted) Navigator.of(context).pop(true);
      }
    });

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(KioskTokens.spaceL),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: AnimatedSize(
          duration: KioskTokens.motionMedium,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _StageContainer(
            child: AnimatedSwitcher(
              duration: KioskTokens.motionMedium,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _buildStage(context, txn, l10n, fmt),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStage(
    BuildContext context,
    PaymentTransaction txn,
    AppLocalizations l10n,
    NumberFormat fmt,
  ) {
    switch (txn.status) {
      case PaymentTransactionStatus.waitingForCard:
      case PaymentTransactionStatus.processing:
      case PaymentTransactionStatus.idle:
        return _TerminalStage(
          key: const ValueKey('terminal'),
          amount: widget.amount,
          fmt: fmt,
          l10n: l10n,
          processing: txn.status == PaymentTransactionStatus.processing,
        );
      case PaymentTransactionStatus.approved:
        return _SuccessStage(
          key: const ValueKey('success'),
          amount: widget.amount,
          fmt: fmt,
          l10n: l10n,
        );
      case PaymentTransactionStatus.printingReceipt:
        return _ReceiptStage(
          key: const ValueKey('receipt'),
          l10n: l10n,
          onFinish: () {
            ref
                .read(paymentProcessControllerProvider.notifier)
                .acknowledgeReceipt();
          },
        );
      case PaymentTransactionStatus.declined:
      case PaymentTransactionStatus.error:
        return _ErrorStage(
          key: const ValueKey('error'),
          l10n: l10n,
          message: txn.message,
          onRetry: () {
            ref.read(paymentProcessControllerProvider.notifier).reset();
            ref
                .read(paymentProcessControllerProvider.notifier)
                .chargeCard(widget.amount);
          },
          onCancel: () {
            ref.read(paymentProcessControllerProvider.notifier).reset();
            Navigator.of(context).pop(false);
          },
        );
      case PaymentTransactionStatus.completed:
        return const SizedBox.shrink(key: ValueKey('completed'));
    }
  }
}

class _StageContainer extends StatelessWidget {
  const _StageContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        KioskTokens.spaceL,
        KioskTokens.spaceXL,
        KioskTokens.spaceL,
        KioskTokens.spaceL,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(KioskTokens.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TerminalStage extends StatefulWidget {
  const _TerminalStage({
    super.key,
    required this.amount,
    required this.fmt,
    required this.l10n,
    required this.processing,
  });

  final double amount;
  final NumberFormat fmt;
  final AppLocalizations l10n;
  final bool processing;

  @override
  State<_TerminalStage> createState() => _TerminalStageState();
}

class _TerminalStageState extends State<_TerminalStage>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _tap;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _tap = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = widget.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 200,
          child: _AnimatedTerminalIcon(
            pulse: _pulse,
            tap: _tap,
            processing: widget.processing,
          ),
        ),
        const SizedBox(height: KioskTokens.spaceL),
        Text(
          widget.processing
              ? l10n.paymentTerminalProcessing
              : l10n.paymentTerminalTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: KioskTokens.spaceS),
        Text(
          widget.processing
              ? l10n.paymentTerminalProcessingBody
              : l10n.paymentTerminalBody,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: KioskTokens.spaceL),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: KioskTokens.spaceL,
            vertical: KioskTokens.spaceM,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(KioskTokens.radiusMedium),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.paymentTerminalAmount,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              Text(
                widget.fmt.format(widget.amount),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedTerminalIcon extends StatelessWidget {
  const _AnimatedTerminalIcon({
    required this.pulse,
    required this.tap,
    required this.processing,
  });

  final AnimationController pulse;
  final AnimationController tap;
  final bool processing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: Listenable.merge([pulse, tap]),
      builder: (context, _) {
        final p = pulse.value;
        final t = Curves.easeInOut.transform(tap.value);
        return Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              Opacity(
                opacity: (1 - ((p + i / 3) % 1)).clamp(0.0, 1.0) * 0.35,
                child: Container(
                  width: 80 + ((p + i / 3) % 1) * 140,
                  height: 80 + ((p + i / 3) % 1) * 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
            ),
            if (processing)
              SizedBox(
                width: 110,
                height: 110,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: scheme.primary,
                ),
              ),
            Transform.translate(
              offset: Offset(0, -10 * t),
              child: Icon(
                Icons.credit_card_rounded,
                size: 72,
                color: scheme.primary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SuccessStage extends StatefulWidget {
  const _SuccessStage({
    super.key,
    required this.amount,
    required this.fmt,
    required this.l10n,
  });

  final double amount;
  final NumberFormat fmt;
  final AppLocalizations l10n;

  @override
  State<_SuccessStage> createState() => _SuccessStageState();
}

class _SuccessStageState extends State<_SuccessStage>
    with TickerProviderStateMixin {
  late final AnimationController _entry;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  static const Color _success = Color(0xFF1F9D55);
  static const Color _onSuccess = Colors.white;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = widget.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 200,
          child: AnimatedBuilder(
            animation: _entry,
            builder: (context, _) {
              final ring = Curves.easeOutCubic.transform(
                (_entry.value * 1.4).clamp(0.0, 1.0),
              );
              final check = Curves.easeOutCubic.transform(
                ((_entry.value - 0.35) / 0.65).clamp(0.0, 1.0),
              );
              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: 0.8 + 0.2 * ring,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: _success.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: ring,
                    child: Container(
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(
                        color: _success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _success.withValues(alpha: 0.45),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  CustomPaint(
                    size: const Size(80, 80),
                    painter: _CheckmarkPainter(
                      progress: check,
                      color: _onSuccess,
                    ),
                  ),
                  // sparkles
                  for (var i = 0; i < 8; i++)
                    _Sparkle(
                      angle: (i / 8) * 2 * math.pi,
                      progress: ring,
                      color: _success,
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: KioskTokens.spaceL),
        Text(
          l10n.paymentSuccessTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: _success,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: KioskTokens.spaceXS),
        Text(
          widget.fmt.format(widget.amount),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: KioskTokens.spaceS),
        Text(
          l10n.paymentApprovedBody,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
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
    final distance = 70 + 30 * progress;
    final dx = math.cos(angle) * distance;
    final dy = math.sin(angle) * distance;
    final opacity = (1 - progress).clamp(0.0, 1.0);
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  _CheckmarkPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final p1 = Offset(size.width * 0.22, size.height * 0.54);
    final p2 = Offset(size.width * 0.44, size.height * 0.74);
    final p3 = Offset(size.width * 0.80, size.height * 0.34);

    final firstLen = (p2 - p1).distance;
    final secondLen = (p3 - p2).distance;
    final total = firstLen + secondLen;
    final drawn = progress * total;

    final path = Path()..moveTo(p1.dx, p1.dy);
    if (drawn <= firstLen) {
      final t = drawn / firstLen;
      path.lineTo(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
    } else {
      path.lineTo(p2.dx, p2.dy);
      final t = ((drawn - firstLen) / secondLen).clamp(0.0, 1.0);
      path.lineTo(p2.dx + (p3.dx - p2.dx) * t, p2.dy + (p3.dy - p2.dy) * t);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _ReceiptStage extends StatefulWidget {
  const _ReceiptStage({
    super.key,
    required this.l10n,
    required this.onFinish,
  });

  final AppLocalizations l10n;
  final VoidCallback onFinish;

  @override
  State<_ReceiptStage> createState() => _ReceiptStageState();
}

class _ReceiptStageState extends State<_ReceiptStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = widget.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 200,
          child: AnimatedBuilder(
            animation: _slide,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_slide.value);
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Printer body
                  Positioned(
                    top: 60,
                    child: Container(
                      width: 180,
                      height: 80,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(
                          KioskTokens.radiusMedium,
                        ),
                        border: Border.all(
                          color: scheme.outlineVariant,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 140,
                          height: 6,
                          decoration: BoxDecoration(
                            color: scheme.outline,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Receipt paper sliding out
                  Positioned(
                    top: 60 - (40 * t),
                    child: Container(
                      width: 130,
                      height: 70 + (60 * t),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < 5; i++) ...[
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: KioskTokens.spaceL),
        Text(
          l10n.paymentReceiptTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: KioskTokens.spaceS),
        Text(
          l10n.paymentReceiptBody,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: KioskTokens.spaceL),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: widget.onFinish,
            icon: const Icon(Icons.check_rounded),
            label: Text(l10n.paymentFinish),
          ),
        ),
      ],
    );
  }
}

class _ErrorStage extends StatelessWidget {
  const _ErrorStage({
    super.key,
    required this.l10n,
    required this.message,
    required this.onRetry,
    required this.onCancel,
  });

  final AppLocalizations l10n;
  final String? message;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close_rounded,
            size: 72,
            color: scheme.error,
          ),
        ),
        const SizedBox(height: KioskTokens.spaceL),
        Text(
          l10n.paymentDeclinedTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: scheme.error,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: KioskTokens.spaceS),
        Text(
          message ?? l10n.paymentDeclinedBody,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: KioskTokens.spaceL),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                child: Text(l10n.cancel),
              ),
            ),
            const SizedBox(width: KioskTokens.spaceS),
            Expanded(
              child: FilledButton(
                onPressed: onRetry,
                child: Text(l10n.paymentRetry),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
