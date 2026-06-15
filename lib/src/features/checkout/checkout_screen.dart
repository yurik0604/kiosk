import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../session/data/session_controller.dart';
import '../session/domain/cart_item.dart';
import 'data/payment_controller.dart';
import 'data/payment_process_controller.dart';
import 'domain/payment_method.dart';
import 'presentation/payment_process_dialog.dart';
import 'presentation/thank_you_dialog.dart';

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
                  items: session.items,
                  fmt: fmt,
                ),
                const SizedBox(height: KioskTokens.spaceXXL),
                Text(
                  l10n.paymentSelectMethods,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(alpha: 0.72),
                      ),
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
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: KioskTokens.spaceM,
                      crossAxisSpacing: KioskTokens.spaceM,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: PaymentMethod.values.length,
                    itemBuilder: (_, index) {
                      final method = PaymentMethod.values[index];
                      return _PaymentMethodTile(
                        method: method,
                        amount: payment.amountFor(method),
                        total: session.total,
                        fmt: fmt,
                        l10n: l10n,
                      );
                    },
                  ),
                ),
                const SizedBox(height: KioskTokens.spaceM),
                _Footer(l10n: l10n),
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
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.72),
                height: 1.0,
              ),
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
    required this.items,
    required this.fmt,
  });

  final double total;
  final double allocated;
  final double remaining;
  final int itemCount;
  final List<CartItem> items;
  final NumberFormat fmt;

  static const int _maxThumbs = 4;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final progress = total <= 0 ? 0.0 : (allocated / total).clamp(0.0, 1.0);
    final fullyPaid = remaining < 0.005 && total > 0;
    final hasAllocation = allocated > 0.005;

    final onCard = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;
    final divider = scheme.outlineVariant;

    return Container(
      padding: const EdgeInsets.all(KioskTokens.spaceXL),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(KioskTokens.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.06),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.14),
            blurRadius: 28,
            spreadRadius: -6,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.total.toUpperCase(),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: muted,
                            letterSpacing: 1.6,
                            fontSize: 15,
                          ),
                    ),
                    const SizedBox(height: KioskTokens.spaceXS),
                    Text(
                      fmt.format(total),
                      style: Theme.of(context)
                          .textTheme
                          .displayLarge
                          ?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.8,
                            height: 1.0,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: KioskTokens.spaceL,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_bag_rounded,
                      color: scheme.primary,
                      size: 26,
                    ),
                    const SizedBox(width: KioskTokens.spaceS),
                    Text(
                      l10n.itemsCount(itemCount),
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: KioskTokens.spaceL),
            Container(height: 1, color: divider),
            const SizedBox(height: KioskTokens.spaceM),
            _CartPreview(
              items: items,
              maxThumbs: _maxThumbs,
              onCard: onCard,
              muted: muted,
            ),
          ],
          if (hasAllocation) ...[
            const SizedBox(height: KioskTokens.spaceL),
            Container(height: 1, color: divider),
            const SizedBox(height: KioskTokens.spaceM),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.paymentAllocated.toUpperCase(),
                        style:
                            Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: muted,
                                  letterSpacing: 1.2,
                                  fontSize: 12,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fmt.format(allocated),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: onCard,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      (fullyPaid ? l10n.paymentAllocated : l10n.paymentRemaining)
                          .toUpperCase(),
                      style:
                          Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: muted,
                                letterSpacing: 1.2,
                                fontSize: 12,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fmt.format(fullyPaid ? allocated : remaining),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            color: fullyPaid
                                ? scheme.tertiary
                                : onCard,
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
                backgroundColor: scheme.outlineVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  fullyPaid ? scheme.tertiary : scheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CartPreview extends StatelessWidget {
  const _CartPreview({
    required this.items,
    required this.maxThumbs,
    required this.onCard,
    required this.muted,
  });

  final List<CartItem> items;
  final int maxThumbs;
  final Color onCard;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final shown = items.take(maxThumbs).toList();
    final overflow = items.length - shown.length;
    const thumbSize = 56.0;
    const overlap = 14.0;
    final stackWidth =
        thumbSize + (shown.length - 1).clamp(0, maxThumbs) * (thumbSize - overlap);

    final names = items
        .take(3)
        .map((i) => i.product.name)
        .join(' · ');

    return Row(
      children: [
        SizedBox(
          width: stackWidth + (overflow > 0 ? thumbSize - overlap : 0),
          height: thumbSize,
          child: Stack(
            children: [
              for (var i = 0; i < shown.length; i++)
                PositionedDirectional(
                  start: i * (thumbSize - overlap),
                  child: _Thumb(
                    item: shown[i],
                    size: thumbSize,
                  ),
                ),
              if (overflow > 0)
                PositionedDirectional(
                  start: shown.length * (thumbSize - overlap),
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.10),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+$overflow',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: KioskTokens.spaceM),
        Expanded(
          child: Text(
            names,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: muted,
                  height: 1.3,
                ),
          ),
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.item, required this.size});

  final CartItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasImage = item.product.imageUrl.isNotEmpty;
    Color fallback;
    try {
      final hex = item.product.colorHex.replaceFirst('#', '');
      fallback = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      fallback = Theme.of(context).colorScheme.tertiary;
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fallback,
        border: Border.all(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          width: 3,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              item.product.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const SizedBox.shrink();
              },
            )
          : null,
    );
  }
}

class _PaymentMethodTile extends ConsumerWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.amount,
    required this.total,
    required this.fmt,
    required this.l10n,
  });

  final PaymentMethod method;
  final double amount;
  final double total;
  final NumberFormat fmt;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = amount > 0.005;
    final canStartPayment = total > 0.005;

    final borderRadius = BorderRadius.circular(KioskTokens.radiusLarge);

    final cardColor = isActive ? scheme.primary : Colors.white;
    final iconBg = isActive
        ? Colors.white.withValues(alpha: 0.18)
        : scheme.primary.withValues(alpha: 0.10);
    final iconColor = isActive ? scheme.onPrimary : scheme.primary;
    final titleColor = isActive
        ? scheme.onPrimary
        : scheme.onSurface.withValues(alpha: 0.72);
    final subtitleColor = isActive
        ? scheme.onPrimary.withValues(alpha: 0.85)
        : scheme.onSurfaceVariant;

    return AnimatedContainer(
      duration: KioskTokens.motionFast,
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: borderRadius,
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.38),
              blurRadius: 36,
              spreadRadius: -2,
              offset: const Offset(0, 14),
            )
          else ...[
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.08),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.16),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 14),
            ),
          ],
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: canStartPayment
              ? () => runPaymentFlow(
                    context: context,
                    ref: ref,
                    method: method,
                    total: total,
                  )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(KioskTokens.spaceM),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: iconBg,
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? Colors.white.withValues(alpha: 0.10)
                            : scheme.primary.withValues(alpha: 0.06),
                      ),
                    ),
                    Icon(method.icon, size: 72, color: iconColor),
                  ],
                ),
                const SizedBox(height: KioskTokens.spaceM),
                Text(
                  method.label(l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                        letterSpacing: -0.4,
                        fontSize: 34,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  isActive ? fmt.format(amount) : method.subtitle(l10n),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: subtitleColor,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w400,
                        fontSize: 18,
                        height: 1.3,
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

class _Footer extends ConsumerWidget {
  const _Footer({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
        onPressed: () {
          ref.read(paymentControllerProvider.notifier).reset();
          context.go(AppRoutes.session);
        },
        icon: const Icon(Icons.arrow_back_rounded),
        label: Text(l10n.back),
      ),
    );
  }
}

Future<void> runPaymentFlow({
  required BuildContext context,
  required WidgetRef ref,
  required PaymentMethod method,
  required double total,
}) async {
  if (total <= 0.005) return;
  HapticFeedback.mediumImpact();
  ref.read(paymentControllerProvider.notifier).payRemainingWith(method);
  final completed = await showPaymentProcessDialog(
    context: context,
    amount: total,
  );
  if (!context.mounted) return;
  ref.read(paymentProcessControllerProvider.notifier).reset();
  if (!completed) {
    ref.read(paymentControllerProvider.notifier).clear(method);
    return;
  }
  await showThankYouDialog(context: context);
  if (!context.mounted) return;
  ref.read(paymentControllerProvider.notifier).reset();
  ref.read(sessionControllerProvider.notifier).reset();
  context.go(AppRoutes.home);
}
