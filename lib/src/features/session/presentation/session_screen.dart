import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/session_controller.dart';
import '../domain/cart_item.dart';
import 'product_card.dart';

class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _Header(
                itemCount: session.itemCount,
                onSimulateScan: () {
                  HapticFeedback.lightImpact();
                  ref.read(sessionControllerProvider.notifier).simulateScan();
                },
              ),
              Expanded(
                child: session.isEmpty
                    ? const _EmptyState()
                    : _ProductList(items: session.items),
              ),
              _Footer(
                total: session.total,
                originalTotal: session.originalTotal,
                savings: session.savings,
                isEmpty: session.isEmpty,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.itemCount, required this.onSimulateScan});
  final int itemCount;
  final VoidCallback onSimulateScan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KioskTokens.spaceL,
        KioskTokens.spaceL,
        KioskTokens.spaceL,
        KioskTokens.spaceM,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.yourBag,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  itemCount == 0
                      ? l10n.placePieces
                      : l10n.piecesAdded(itemCount),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          _SimulateScanButton(onPressed: onSimulateScan),
          const SizedBox(width: KioskTokens.spaceS),
          _ScanIndicator(),
        ],
      ),
    );
  }
}

class _SimulateScanButton extends StatelessWidget {
  const _SimulateScanButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: l10n.simulateScan,
      child: Material(
        color: scheme.tertiary,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              Icons.touch_app_rounded,
              color: scheme.onTertiary,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanIndicator extends StatefulWidget {
  @override
  State<_ScanIndicator> createState() => _ScanIndicatorState();
}

class _ScanIndicatorState extends State<_ScanIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 96,
      height: 96,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            for (int i = 0; i < 3; i++)
              Opacity(
                opacity:
                    (1 - ((_controller.value + i / 3) % 1)).clamp(0.0, 0.6),
                child: Container(
                  width: 56 + ((_controller.value + i / 3) % 1) * 32,
                  height: 56 + ((_controller.value + i / 3) % 1) * 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.primary, width: 2),
                  ),
                ),
              ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.nfc_rounded,
                color: scheme.onPrimaryContainer,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KioskTokens.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.checkroom_rounded,
                size: 80,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KioskTokens.spaceL),
            Text(
              l10n.bagEmpty,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: KioskTokens.spaceXS),
            Text(
              l10n.bagEmptyHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductList extends ConsumerWidget {
  const _ProductList({required this.items});
  final List<CartItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: KioskTokens.spaceL,
        vertical: KioskTokens.spaceS,
      ),
      itemCount: items.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: KioskTokens.spaceS),
      itemBuilder: (_, index) {
        final item = items[index];
        return ProductCard(
          key: ValueKey(item.lineId),
          item: item,
          onRemove: () => ref
              .read(sessionControllerProvider.notifier)
              .removeItem(item.lineId),
        );
      },
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({
    required this.total,
    required this.originalTotal,
    required this.savings,
    required this.isEmpty,
  });
  final double total;
  final double originalTotal;
  final double savings;
  final bool isEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final fmt = NumberFormat.simpleCurrency(
      locale: Localizations.localeOf(context).toString(),
      name: 'ILS',
    );
    final hasSavings = savings > 0.005;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        KioskTokens.spaceL,
        KioskTokens.spaceM,
        KioskTokens.spaceL,
        KioskTokens.spaceL,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(KioskTokens.radiusLarge),
        ),
      ),
      child: Column(
        children: [
          if (hasSavings) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.subtotal,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      fmt.format(originalTotal),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.lineThrough,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.youSaved(fmt.format(savings)),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontSize: 13,
                              color: scheme.onErrorContainer,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: KioskTokens.spaceXS),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                l10n.total,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              AnimatedSwitcher(
                duration: KioskTokens.motionMedium,
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Text(
                  fmt.format(total),
                  key: ValueKey(total),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: scheme.primary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KioskTokens.spaceM),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _confirmCancel(context, ref),
                  icon: const Icon(Icons.close_rounded),
                  label: Text(l10n.cancel),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  ),
                ),
              ),
              const SizedBox(width: KioskTokens.spaceS),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: isEmpty
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          context.go(AppRoutes.checkout);
                        },
                  icon: const Icon(Icons.lock_rounded),
                  label: Text(l10n.checkout),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KioskTokens.radiusMedium),
        ),
        title: Text(l10n.cancelSessionTitle),
        content: Text(l10n.cancelSessionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.keepShopping),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.cancelSession),
          ),
        ],
      ),
    );
    if (result == true && context.mounted) {
      ref.read(sessionControllerProvider.notifier).reset();
      context.go(AppRoutes.home);
    }
  }
}

