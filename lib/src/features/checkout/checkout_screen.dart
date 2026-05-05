import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../session/data/session_controller.dart';
import 'data/payment_controller.dart';
import 'domain/payment_method.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final payment = ref.watch(paymentControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final fmt = NumberFormat.simpleCurrency(
      locale: Localizations.localeOf(context).toString(),
      name: 'ILS',
    );

    final remaining = (session.total - payment.allocated)
        .clamp(0.0, double.infinity);
    final canPay = session.total > 0 && remaining < 0.005;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(KioskTokens.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(l10n: l10n),
                const SizedBox(height: KioskTokens.spaceL),
                _TotalsCard(
                  total: session.total,
                  allocated: payment.allocated,
                  remaining: remaining,
                  itemCount: session.itemCount,
                  fmt: fmt,
                ),
                const SizedBox(height: KioskTokens.spaceL),
                Text(
                  l10n.paymentSelectMethods,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: KioskTokens.spaceXS),
                Text(
                  l10n.paymentSplitHint,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: KioskTokens.spaceM),
                Expanded(
                  child: ListView.separated(
                    itemCount: PaymentMethod.values.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: KioskTokens.spaceS),
                    itemBuilder: (_, index) {
                      final method = PaymentMethod.values[index];
                      return _PaymentMethodTile(
                        method: method,
                        amount: payment.amountFor(method),
                        fmt: fmt,
                        l10n: l10n,
                      );
                    },
                  ),
                ),
                const SizedBox(height: KioskTokens.spaceM),
                _Footer(
                  canPay: canPay,
                  total: session.total,
                  fmt: fmt,
                  l10n: l10n,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => context.go(AppRoutes.session),
          icon: const Icon(Icons.arrow_back_rounded, size: 32),
        ),
        const SizedBox(width: KioskTokens.spaceS),
        Text(
          l10n.checkoutTitle,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.total,
    required this.allocated,
    required this.remaining,
    required this.itemCount,
    required this.fmt,
  });

  final double total;
  final double allocated;
  final double remaining;
  final int itemCount;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final progress = total <= 0 ? 0.0 : (allocated / total).clamp(0.0, 1.0);
    final fullyPaid = remaining < 0.005 && total > 0;

    return Container(
      padding: const EdgeInsets.all(KioskTokens.spaceL),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KioskTokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.total,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fmt.format(total),
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(color: scheme.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.itemsCount(itemCount),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fullyPaid ? l10n.paymentAllocated : l10n.paymentRemaining,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fmt.format(fullyPaid ? allocated : remaining),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: fullyPaid ? scheme.tertiary : scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: KioskTokens.spaceM),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                fullyPaid ? scheme.tertiary : scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.amount,
    required this.fmt,
    required this.l10n,
  });

  final PaymentMethod method;
  final double amount;
  final NumberFormat fmt;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = amount > 0.005;

    return Container(
      decoration: BoxDecoration(
        color: isActive ? scheme.primaryContainer : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KioskTokens.radiusMedium),
        border: Border.all(
          color: isActive ? scheme.primary : scheme.outlineVariant,
          width: isActive ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: KioskTokens.spaceL,
        vertical: KioskTokens.spaceM,
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isActive
                  ? scheme.primary
                  : scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              method.icon,
              size: 32,
              color: isActive ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: KioskTokens.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.label(l10n),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                      ),
                ),
                if (isActive) ...[
                  const SizedBox(height: 4),
                  Text(
                    fmt.format(amount),
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({
    required this.canPay,
    required this.total,
    required this.fmt,
    required this.l10n,
  });

  final bool canPay;
  final double total;
  final NumberFormat fmt;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              ref.read(paymentControllerProvider.notifier).reset();
              context.go(AppRoutes.session);
            },
            child: Text(l10n.back),
          ),
        ),
        const SizedBox(width: KioskTokens.spaceS),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: canPay ? () => _confirmAndFinish(context, ref) : null,
            icon: const Icon(Icons.lock_rounded),
            label: Text(l10n.paymentPayNow(fmt.format(total))),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndFinish(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KioskTokens.radiusMedium),
        ),
        icon: Icon(
          Icons.check_circle_rounded,
          size: 64,
          color: Theme.of(ctx).colorScheme.tertiary,
        ),
        title: Text(
          l10n.paymentSuccessTitle,
          textAlign: TextAlign.center,
        ),
        content: Text(
          l10n.paymentSuccessBody,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.paymentDone),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    ref.read(paymentControllerProvider.notifier).reset();
    ref.read(sessionControllerProvider.notifier).reset();
    context.go(AppRoutes.home);
  }
}
