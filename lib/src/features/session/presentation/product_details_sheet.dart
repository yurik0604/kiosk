import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/format/currency.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../catalog/domain/barcode.dart';
import '../data/session_controller.dart';
import '../domain/cart_item.dart';
import 'product_card.dart';

Future<void> showProductDetailsSheet({
  required BuildContext context,
  required CartItem item,
  required VoidCallback onRemove,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _ProductDetailsSheet(item: item, onRemove: onRemove),
  );
}

class _ProductDetailsSheet extends StatelessWidget {
  const _ProductDetailsSheet({required this.item, required this.onRemove});

  final CartItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final fmt = NumberFormat.simpleCurrency(
      locale: Localizations.localeOf(context).toString(),
      name: 'ILS',
    );
    final p = item.product;

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(KioskTokens.radiusLarge),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        _HeroImage(
                          imageUrl: p.imageUrl,
                          category: p.category,
                          subCategory: p.subCategory,
                        ),
                        PositionedDirectional(
                          top: 16,
                          start: 0,
                          end: 0,
                          child: Center(
                            child: Container(
                              width: 64,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      KioskTokens.spaceL,
                      KioskTokens.spaceL,
                      KioskTokens.spaceL,
                      KioskTokens.spaceM,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _DetailsBody(
                        item: item,
                        fmt: fmt,
                        l10n: l10n,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _Actions(
              onRemove: () async {
                HapticFeedback.mediumImpact();
                final confirmed = await _confirmRemove(context);
                if (!confirmed) return;
                if (!context.mounted) return;
                Navigator.of(context).pop();
                onRemove();
              },
              onClose: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({
    required this.imageUrl,
    required this.category,
    required this.subCategory,
  });

  final String imageUrl;
  final String category;
  final String subCategory;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (imageUrl.isEmpty) {
      return AspectRatio(
        aspectRatio: 4 / 5,
        child: ColoredBox(
          color: scheme.primaryContainer,
          child: Center(
            child: Icon(
              productFallbackIcon(category, subCategory),
              size: 96,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
      );
    }
    return Image.network(
      imageUrl,
      width: double.infinity,
      fit: BoxFit.fitWidth,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return AspectRatio(
          aspectRatio: 4 / 5,
          child: ColoredBox(
            color: scheme.primaryContainer,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.onPrimaryContainer.withValues(alpha: 0.4),
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, _, _) => AspectRatio(
        aspectRatio: 4 / 5,
        child: ColoredBox(
          color: scheme.primaryContainer,
          child: Center(
            child: Icon(
              productFallbackIcon(category, subCategory),
              size: 96,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({
    required this.item,
    required this.fmt,
    required this.l10n,
  });

  final CartItem item;
  final NumberFormat fmt;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final product = item.product;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.brand.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.secondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.2,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          product.name,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
        ),
        const SizedBox(height: KioskTokens.spaceS),
        Builder(
          builder: (context) {
            final ean = Ean13.fromSku(product.sku);
            return Semantics(
              label: l10n.barcodeLabel(ean.digits),
              child: Row(
                children: [
                  Icon(
                    Icons.qr_code_2_rounded,
                    size: 22,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      ean.formatted,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            letterSpacing: 0.6,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: KioskTokens.spaceL),
        _PriceBlock(item: item, l10n: l10n),
        const SizedBox(height: KioskTokens.spaceL),
        Wrap(
          spacing: KioskTokens.spaceS,
          runSpacing: KioskTokens.spaceS,
          children: [
            _DetailChip(icon: Icons.straighten_rounded, label: product.size),
            _DetailChip(
              icon: Icons.palette_outlined,
              label: product.color,
              swatchColor: _parseHex(product.colorHex),
            ),
            if (product.subCategory.isNotEmpty)
              _DetailChip(
                icon: Icons.category_outlined,
                label: product.subCategory,
              ),
            _DetailChip(
              icon: Icons.person_outline_rounded,
              label: _localizedGender(l10n, product.gender),
            ),
            if (product.season.isNotEmpty)
              _DetailChip(icon: Icons.event_outlined, label: product.season),
            _DetailChip(
              icon: Icons.inventory_2_outlined,
              label: l10n.stockCount(product.stockQty),
            ),
            _DetailChip(
              icon: Icons.confirmation_number_outlined,
              label: l10n.skuLabel(product.sku),
            ),
          ],
        ),
        const SizedBox(height: KioskTokens.spaceL),
        Container(
          height: 1,
          color: scheme.outlineVariant.withValues(alpha: 0.6),
        ),
        const SizedBox(height: KioskTokens.spaceL),
        Text(
          product.description,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: KioskTokens.spaceL),
        _DetailSection(title: l10n.sectionMaterial, body: product.material),
        if (product.origin.isNotEmpty) ...[
          const SizedBox(height: KioskTokens.spaceM),
          _DetailSection(title: l10n.sectionOrigin, body: product.origin),
        ],
        if (product.careInstructions.isNotEmpty) ...[
          const SizedBox(height: KioskTokens.spaceM),
          _DetailSection(
            title: l10n.sectionCare,
            body: product.careInstructions,
          ),
        ],
      ],
    );
  }

  static Color _parseHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length != 6) return Colors.black12;
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  static String _localizedGender(AppLocalizations l10n, String raw) {
    switch (raw.toLowerCase()) {
      case 'men':
        return l10n.genderMen;
      case 'women':
        return l10n.genderWomen;
      case 'unisex':
        return l10n.genderUnisex;
      default:
        return raw;
    }
  }
}

class _PriceBlock extends ConsumerWidget {
  const _PriceBlock({required this.item, required this.l10n});
  final CartItem item;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final product = item.product;

    final session = ref.watch(sessionControllerProvider);
    final memberSaves = session.memberSavingsFor(item);
    final effectivePrice = session.effectivePriceFor(item);
    final hasMemberDiscount = memberSaves > 0.005;
    final saleSavings = product.originalPrice - product.price;

    // Compose amounts with the mark-free, symbol-left formatter so the ₪ and the
    // minus sit consistently and RTL can't reorder them — same as the card and
    // the totals panel.
    final cf = CurrencyFormat.of(
      Localizations.localeOf(context).toString(),
      name: 'ILS',
    );

    final titleLarge = Theme.of(context).textTheme.titleLarge;
    final labelStyle = titleLarge?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final originalStyle = titleLarge?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.lineThrough,
    );
    final discountLabelStyle = titleLarge?.copyWith(
      color: scheme.error,
      fontWeight: FontWeight.w600,
    );
    final discountAmountStyle = titleLarge?.copyWith(
      color: scheme.error,
      fontWeight: FontWeight.w700,
    );
    final totalLabelStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w800,
    );
    final totalStyle = Theme.of(context).textTheme.displaySmall?.copyWith(
      color: scheme.primary,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    );

    // Discount context, if any (sale takes precedence over member pricing).
    final ({
      String label,
      double original,
      double savings,
      TextStyle? labelStyle,
    })? discount;
    if (product.isOnSale) {
      discount = (
        label: l10n.saleDiscountShort,
        original: product.originalPrice,
        savings: saleSavings,
        labelStyle: discountLabelStyle,
      );
    } else if (hasMemberDiscount) {
      discount = (
        label: l10n.memberDiscountLineLabel(
          _formatPercent(session.memberDiscountPct),
        ),
        original: product.price,
        savings: memberSaves,
        labelStyle: discountLabelStyle,
      );
    } else {
      discount = null;
    }

    // Dot-align the original and the discount: their whole parts share a fixed
    // slot (the wider of the two, measured) so the decimal points stack — dot
    // below dot — exactly like the product card. The emphasized total sits on
    // its own row below.
    final children = <Widget>[];
    if (discount != null) {
      final originalParts = cf.formatParts(discount.original);
      final savingsParts = cf.formatParts(discount.savings, signed: true);
      final wholeSlot = math.max(
        Currency.measureWidth(originalParts.whole, originalStyle),
        Currency.measureWidth(savingsParts.whole, discountAmountStyle),
      );
      children.add(
        _priceLine(
          label: Text(l10n.subtotal, style: labelStyle),
          amount: Currency.decimalAligned(
            originalParts,
            style: originalStyle,
            wholeSlot: wholeSlot,
          ),
        ),
      );
      children.add(const SizedBox(height: KioskTokens.spaceXS));
      children.add(
        _priceLine(
          label: Text(discount.label, style: discount.labelStyle),
          amount: Currency.decimalAligned(
            savingsParts,
            style: discountAmountStyle,
            wholeSlot: wholeSlot,
          ),
        ),
      );
      children.add(const SizedBox(height: KioskTokens.spaceS));
    }
    children.add(
      _priceLine(
        label: Text(l10n.total, style: totalLabelStyle),
        amount: Currency.amount(cf.format(effectivePrice), style: totalStyle),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(KioskTokens.spaceM),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KioskTokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  /// One label ↔ amount line: the label hugs the panel's start edge (right in
  /// RTL) and the amount its end edge (left in RTL), the amounts sharing a
  /// trailing edge so their decimal points align down the column.
  Widget _priceLine({required Widget label, required Widget amount}) => Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Expanded(child: label),
      amount,
    ],
  );
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.label,
    this.swatchColor,
  });

  final IconData icon;
  final String label;
  final Color? swatchColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (swatchColor != null) ...[
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: swatchColor,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outlineVariant, width: 1),
              ),
            ),
            const SizedBox(width: 10),
          ] else ...[
            Icon(icon, size: 20, color: scheme.onSurfaceVariant),
            const SizedBox(width: 10),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.secondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.onRemove, required this.onClose});
  final VoidCallback onRemove;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        KioskTokens.spaceL,
        KioskTokens.spaceM,
        KioskTokens.spaceL,
        MediaQuery.viewPaddingOf(context).bottom + KioskTokens.spaceM,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: KioskTokens.touchTargetLarge,
            height: KioskTokens.touchTargetLarge,
            // Destructive delete: outlined (not solid) red so it reads as the
            // dangerous action without out-shouting the safe "keep shopping"
            // primary beside it.
            child: OutlinedButton(
              onPressed: onRemove,
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error, width: 2),
                padding: EdgeInsets.zero,
              ),
              child: Tooltip(
                message: l10n.removeFromBag,
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 28,
                  color: scheme.error,
                ),
              ),
            ),
          ),
          const SizedBox(width: KioskTokens.spaceS),
          Expanded(
            child: FilledButton(
              onPressed: onClose,
              style: FilledButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: Text(
                l10n.keepShopping.toUpperCase(),
                style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 26,
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

Future<bool> _confirmRemove(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final scheme = theme.colorScheme;
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: KioskTokens.spaceXL,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KioskTokens.radiusLarge),
        ),
        backgroundColor: scheme.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KioskTokens.spaceXL,
              KioskTokens.spaceXL,
              KioskTokens.spaceXL,
              KioskTokens.spaceL,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 48,
                    color: scheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: KioskTokens.spaceL),
                Text(
                  l10n.removeFromBagTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                ),
                const SizedBox(height: KioskTokens.spaceM),
                Text(
                  l10n.removeFromBagBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: KioskTokens.spaceXL),
                FilledButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  icon: const Icon(Icons.arrow_back_rounded,
                      size: 28, color: Colors.white),
                  label: Text(
                    l10n.keepShopping.toUpperCase(),
                    style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                  ),
                  style: FilledButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: KioskTokens.spaceS),
                FilledButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 28, color: Colors.white),
                  label: Text(
                    l10n.removeFromBagConfirm.toUpperCase(),
                    style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return result ?? false;
}

String _formatPercent(double pct) {
  if (pct == pct.roundToDouble()) return pct.toStringAsFixed(0);
  return pct.toStringAsFixed(1);
}
