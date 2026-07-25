import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/phone_entry_dialog.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../member/data/current_shopper_controller.dart';
import '../data/payment_process_controller.dart';
import '../data/receipt_delivery_service.dart';
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
      // Once the receipt has been delivered, the flow is done — close the dialog.
      if (prev?.status != PaymentTransactionStatus.completed &&
          next.status == PaymentTransactionStatus.completed) {
        HapticFeedback.mediumImpact();
        if (mounted) Navigator.of(context).pop(true);
      }
    });

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(KioskTokens.spaceL),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: _StageContainer(
          child: AnimatedSwitcher(
            duration: KioskTokens.motionMedium,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
                  child: child,
                ),
              );
            },
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  ...previousChildren,
                  ?currentChild,
                ],
              );
            },
            child: _buildStage(context, txn, l10n, fmt),
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
          onContinue: () =>
              ref.read(paymentProcessControllerProvider.notifier).chooseReceipt(),
        );
      case PaymentTransactionStatus.choosingReceipt:
        return _ReceiptChoiceStage(
          key: const ValueKey('receipt-choice'),
          l10n: l10n,
          onConfirm: (includeExchangeSlip, delivery) =>
              _startDelivery(txn, includeExchangeSlip, delivery),
        );
      case PaymentTransactionStatus.printingReceipt:
        return _DeliveryStage(
          key: const ValueKey('printing'),
          title: l10n.paymentPrintingTitle,
          body: l10n.paymentPrintingBody,
          kind: _DeliveryKind.print,
        );
      case PaymentTransactionStatus.sendingSms:
        return _DeliveryStage(
          key: const ValueKey('sending-sms'),
          title: l10n.paymentSendingSmsTitle,
          body: l10n.paymentSendingSmsBody(
            ref.read(currentShopperProvider).effectivePhone ?? '',
          ),
          kind: _DeliveryKind.sms,
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

  /// Tail of the post-payment handler chain: resolves the delivery target
  /// (prompting for a phone if SMS is chosen and none is on file), assembles the
  /// [ReceiptJob], then hands off to the controller to run the print / SMS
  /// delivery. Reads member + phone from the session-scoped current shopper.
  Future<void> _startDelivery(
    PaymentTransaction txn,
    bool includeExchangeSlip,
    ReceiptDelivery delivery,
  ) async {
    final shopper = ref.read(currentShopperProvider);
    String? phone = shopper.effectivePhone;

    if (delivery == ReceiptDelivery.sms && phone == null) {
      // SMS chosen but no phone captured earlier — ask for it now.
      final entered = await showPhoneEntryDialog(context);
      if (entered == null || entered.isEmpty) {
        // Cancelled phone entry — stay on the receipt-choice step.
        return;
      }
      ref.read(currentShopperProvider.notifier).setPhone(entered);
      phone = entered;
    }

    final job = ReceiptJob(
      transactionId: txn.transactionId,
      amount: txn.amount,
      includeExchangeSlip: includeExchangeSlip,
      phone: delivery == ReceiptDelivery.sms ? phone : null,
    );

    await ref
        .read(paymentProcessControllerProvider.notifier)
        .deliverReceipt(job, delivery: delivery);
  }
}

class _StageContainer extends StatelessWidget {
  const _StageContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
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
  late final AnimationController _progress;

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
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.processing) _progress.repeat();
  }

  @override
  void didUpdateWidget(covariant _TerminalStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.processing && !oldWidget.processing) {
      _progress.repeat();
    } else if (!widget.processing && oldWidget.processing) {
      _progress.stop();
      _progress.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _tap.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = widget.l10n;
    return SizedBox(
      height: 540,
      child: Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Flexible (up to 260) so the icon yields height when the text/amount
        // block is tall — e.g. at larger locale font scales — instead of the
        // fixed-height stage overflowing at the bottom.
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: _AnimatedTerminalIcon(
              pulse: _pulse,
              tap: _tap,
              processing: widget.processing,
            ),
          ),
        ),
        const SizedBox(height: KioskTokens.spaceXL),
        Text(
          widget.processing
              ? l10n.paymentTerminalProcessing
              : l10n.paymentTerminalTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: KioskTokens.spaceS),
        Text(
          widget.processing
              ? l10n.paymentTerminalProcessingBody
              : l10n.paymentTerminalBody,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
        ),
        const SizedBox(height: KioskTokens.spaceL),
        if (widget.processing) ...[
          _DashedProgress(
            progress: _progress,
            color: scheme.primary,
            active: true,
          ),
          const SizedBox(height: KioskTokens.spaceL),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            KioskTokens.spaceL,
            KioskTokens.spaceM,
            KioskTokens.spaceL,
            KioskTokens.spaceM,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary.withValues(alpha: 0.10),
                scheme.primary.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(KioskTokens.radiusMedium),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.18),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                l10n.paymentTerminalAmount.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.fmt.format(widget.amount),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      height: 1.0,
                    ),
              ),
            ],
          ),
        ),
      ],
    ),
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
        final cardLift = processing ? 0.0 : (-18 * t);
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Outer soft glow.
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    scheme.primary.withValues(alpha: 0.16),
                    scheme.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            // NFC ripple waves above the card.
            for (var i = 0; i < 3; i++)
              Positioned(
                top: 8 + ((p + i / 3) % 1) * -40,
                child: Opacity(
                  opacity: (1 - ((p + i / 3) % 1)).clamp(0.0, 1.0) * 0.55,
                  child: _NfcArc(
                    color: scheme.primary,
                    width: 70 + ((p + i / 3) % 1) * 60,
                  ),
                ),
              ),
            // Payment terminal (bottom slab).
            Positioned(
              bottom: 6,
              child: _TerminalDevice(scheme: scheme, processing: processing),
            ),
            // Floating credit card.
            Transform.translate(
              offset: Offset(0, -56 + cardLift),
              child: Transform.rotate(
                angle: processing ? 0 : -0.06 + 0.02 * t,
                child: _CreditCard(scheme: scheme),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CreditCard extends StatelessWidget {
  const _CreditCard({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 124,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, Colors.black, 0.35) ?? scheme.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.45),
            blurRadius: 28,
            spreadRadius: -4,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chip.
              Container(
                width: 32,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFD86B), Color(0xFFB68A2C)],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: Colors.black.withValues(alpha: 0.2),
                    ),
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: Colors.black.withValues(alpha: 0.2),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.wifi_rounded,
                size: 22,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ],
          ),
          const Spacer(),
          // Faux card number.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 4; i++)
                Container(
                  width: 30,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'KIOSK PAY',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminalDevice extends StatelessWidget {
  const _TerminalDevice({required this.scheme, required this.processing});

  final ColorScheme scheme;
  final bool processing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 48,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(14),
          bottom: Radius.circular(6),
        ),
        border: Border.all(
          color: scheme.outlineVariant,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 6,
            decoration: BoxDecoration(
              color: processing
                  ? scheme.primary
                  : scheme.primary.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: scheme.outline.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedProgress extends StatelessWidget {
  const _DashedProgress({
    required this.progress,
    required this.color,
    required this.active,
  });

  final Animation<double> progress;
  final Color color;
  final bool active;

  static const int segments = 4;

  @override
  Widget build(BuildContext context) {
    final mutedColor = color.withValues(alpha: 0.18);
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final activeIndex = active
            ? (progress.value * segments).floor().clamp(0, segments - 1)
            : -1;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(segments, (i) {
            final isOn = i == activeIndex;
            return Padding(
              padding: EdgeInsets.only(
                left: i == 0 ? 0 : 4,
                right: i == segments - 1 ? 0 : 4,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 42,
                height: 6,
                decoration: BoxDecoration(
                  color: isOn ? color : mutedColor,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: isOn
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.45),
                            blurRadius: 8,
                            spreadRadius: -1,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _NfcArc extends StatelessWidget {
  const _NfcArc({required this.color, required this.width});

  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, width * 0.55),
      painter: _NfcArcPainter(color: color),
    );
  }
}

class _NfcArcPainter extends CustomPainter {
  _NfcArcPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    canvas.drawArc(rect, math.pi * 1.15, math.pi * 0.7, false, paint);
  }

  @override
  bool shouldRepaint(_NfcArcPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SuccessStage extends StatefulWidget {
  const _SuccessStage({
    super.key,
    required this.amount,
    required this.fmt,
    required this.l10n,
    required this.onContinue,
  });

  final double amount;
  final NumberFormat fmt;
  final AppLocalizations l10n;
  final VoidCallback onContinue;

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
    return SizedBox(
      height: 540,
      child: Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
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
        const SizedBox(height: KioskTokens.spaceL),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: widget.onContinue,
            style: FilledButton.styleFrom(foregroundColor: Colors.white),
            child: Text(
              l10n.paymentFinish.toUpperCase(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
            ),
          ),
        ),
      ],
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

/// The receipt-choice step shown after a successful payment: pick whether to
/// include an exchange slip, then how to receive the documents (print / SMS).
/// Confirms with `(includeExchangeSlip, delivery)`.
class _ReceiptChoiceStage extends StatefulWidget {
  const _ReceiptChoiceStage({
    super.key,
    required this.l10n,
    required this.onConfirm,
  });

  final AppLocalizations l10n;
  final void Function(bool includeExchangeSlip, ReceiptDelivery delivery)
      onConfirm;

  @override
  State<_ReceiptChoiceStage> createState() => _ReceiptChoiceStageState();
}

class _ReceiptChoiceStageState extends State<_ReceiptChoiceStage> {
  bool _includeExchangeSlip = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = widget.l10n;

    return SizedBox(
      height: 540,
      // Scrollable so the sections never overflow the fixed stage height at
      // larger locale font scales; centered while the content fits.
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 48,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: KioskTokens.spaceL),
          // Modal title: the general receipt process.
          Text(
            l10n.receiptChoiceTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: KioskTokens.spaceS),
          Text(
            l10n.receiptChoiceBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: KioskTokens.spaceXXL),
          // Section 1 — what to include: the exchange-slip opt-in checkbox.
          _ExchangeSlipCheckbox(
            label: l10n.exchangeSlipYes,
            value: _includeExchangeSlip,
            onChanged: (v) => setState(() => _includeExchangeSlip = v),
          ),
          // Divider separating the "include" and "send by" sections.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: KioskTokens.spaceL),
            child: Divider(height: 1, color: scheme.outlineVariant),
          ),
          // Section 2 — how to receive it: print or SMS.
          Row(
            children: [
              Expanded(
                child: _DeliveryButton(
                  icon: Icons.print_rounded,
                  label: l10n.receiptDeliveryPrint,
                  onTap: () => widget.onConfirm(
                    _includeExchangeSlip,
                    ReceiptDelivery.print,
                  ),
                ),
              ),
              const SizedBox(width: KioskTokens.spaceS),
              Expanded(
                child: _DeliveryButton(
                  icon: Icons.sms_rounded,
                  label: l10n.receiptDeliverySms,
                  onTap: () => widget.onConfirm(
                    _includeExchangeSlip,
                    ReceiptDelivery.sms,
                  ),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }
}

/// A single, tappable checkbox row for opting into the exchange slip.
class _ExchangeSlipCheckbox extends StatelessWidget {
  const _ExchangeSlipCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SizedBox(
      height: KioskTokens.touchTargetLarge,
      child: Material(
        color: value ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(KioskTokens.radiusLarge),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          // Tapping anywhere on the row toggles the checkbox.
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KioskTokens.spaceL,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Checkbox(
                    value: value,
                    onChanged: (v) => onChanged(v ?? false),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(KioskTokens.radiusSmall),
                    ),
                  ),
                ),
                const SizedBox(width: KioskTokens.spaceM),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeliveryButton extends StatelessWidget {
  const _DeliveryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 28),
      label: Text(
        label,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
      ),
      style: FilledButton.styleFrom(foregroundColor: Colors.white),
    );
  }
}

enum _DeliveryKind { print, sms }

/// In-flight delivery animation: a printer emitting a receipt (print) or an
/// envelope flying to a phone (SMS). Pure animation — it auto-completes when the
/// controller's delivery future resolves.
class _DeliveryStage extends StatefulWidget {
  const _DeliveryStage({
    super.key,
    required this.title,
    required this.body,
    required this.kind,
  });

  final String title;
  final String body;
  final _DeliveryKind kind;

  @override
  State<_DeliveryStage> createState() => _DeliveryStageState();
}

class _DeliveryStageState extends State<_DeliveryStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 540,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 200,
            child: AnimatedBuilder(
              animation: _loop,
              builder: (context, _) {
                final t = Curves.easeInOut.transform(_loop.value);
                return widget.kind == _DeliveryKind.print
                    ? _PrinterAnimation(t: t, scheme: scheme)
                    : _SmsAnimation(t: t, scheme: scheme);
              },
            ),
          ),
          const SizedBox(height: KioskTokens.spaceL),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: KioskTokens.spaceS),
          Text(
            widget.body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: KioskTokens.spaceL),
          _DashedProgress(
            progress: _loop,
            color: scheme.primary,
            active: true,
          ),
        ],
      ),
    );
  }
}

/// The printer-emitting-a-receipt loop (extracted from the former receipt
/// stage).
class _PrinterAnimation extends StatelessWidget {
  const _PrinterAnimation({required this.t, required this.scheme});

  final double t;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 60,
          child: Container(
            width: 180,
            height: 80,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(KioskTokens.radiusMedium),
              border: Border.all(color: scheme.outlineVariant, width: 2),
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
  }
}

/// An envelope rising toward a phone, with SMS bubbles — the SMS-sending loop.
class _SmsAnimation extends StatelessWidget {
  const _SmsAnimation({required this.t, required this.scheme});

  final double t;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Phone outline.
        Container(
          width: 96,
          height: 168,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(KioskTokens.radiusMedium),
            border: Border.all(color: scheme.outlineVariant, width: 3),
          ),
        ),
        // Envelope floating up and fading as it "sends".
        Transform.translate(
          offset: Offset(0, 30 - 70 * t),
          child: Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Container(
              width: 64,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.mail_rounded,
                color: scheme.onPrimary,
                size: 28,
              ),
            ),
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
