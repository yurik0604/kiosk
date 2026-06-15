import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/currency.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../catalog/domain/barcode.dart';
import '../data/session_controller.dart';
import '../domain/cart_item.dart';
import 'product_details_sheet.dart';

const double _kCardMinHeight = 176;
const double _kImageWidth = 160;

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.item, required this.onRemove});

  final CartItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = CurrencyFormat.of(
      Localizations.localeOf(context).toString(),
      name: 'ILS',
    );
    final p = item.product;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(KioskTokens.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(KioskTokens.radiusLarge),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            showProductDetailsSheet(
              context: context,
              item: item,
              onRemove: onRemove,
            );
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _kCardMinHeight),
            // The card height is driven by the content Row. The image is
            // painted behind it, filling the leading image column via
            // Positioned — so a tall/portrait photo can't stretch the card
            // (Positioned children contribute no intrinsic size).
            child: Stack(
              children: [
                PositionedDirectional(
                  top: 0,
                  bottom: 0,
                  start: 0,
                  width: _kImageWidth,
                  child: _ProductImage(
                    imageUrl: p.imageUrl,
                    category: p.category,
                    subCategory: p.subCategory,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Spacer reserving the image column's width.
                    const SizedBox(width: _kImageWidth),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: KioskTokens.spaceM,
                          vertical: KioskTokens.spaceS,
                        ),
                        child: _ProductBody(item: item, fmt: fmt),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductBody extends StatelessWidget {
  const _ProductBody({required this.item, required this.fmt});
  final CartItem item;
  final CurrencyFormat fmt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final product = item.product;

    final chips = _FadingChipRow(
      children: [
        _InfoChip(icon: Icons.straighten_rounded, label: product.size),
        _InfoChip(
          icon: Icons.palette_outlined,
          label: product.color,
          swatchColor: _parseHex(product.colorHex),
        ),
        if (product.subCategory.isNotEmpty)
          _InfoChip(icon: Icons.category_outlined, label: product.subCategory),
        _InfoChip(
          icon: Icons.person_outline_rounded,
          label: _localizedGender(l10n, product.gender),
        ),
      ],
    );

    final ean = Ean13.fromSku(product.sku);
    final barcode = Semantics(
      label: l10n.barcodeLabel(ean.digits),
      child: Row(
        children: [
          Icon(
            Icons.qr_code_2_rounded,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              ean.formatted,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.onSurfaceVariant,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1 — brand / model name, full width, single line.
        Text(
          product.brand.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: scheme.secondary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        // Row 2 — product name spanning the full width on a single line,
        // cut with an ellipsis when too long.
        Text(
          product.name,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.72),
            height: 1.15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
        const SizedBox(height: KioskTokens.spaceXS),
        // Row 3 — a 2-column grid whose rows are aligned pairwise with the
        // price column: the attribute chips always sit on the final-price row,
        // and the barcode sits on the discount row (or directly above the
        // chips when there is no discount).
        _DetailsPriceGrid(item: item, fmt: fmt, barcode: barcode, chips: chips),
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

/// Row 3 of the card body: a two-column [Table] that keeps the left column
/// (barcode / chips / discount label) aligned row-for-row with the price
/// column. The price column is [IntrinsicColumnWidth] and end-aligned, so every
/// amount hugs the card's trailing border (decimals line up), matching the
/// totals panel.
///
///   no discount              with discount
///   ┌────────────┬────────┐  ┌──────────────┬────────────┐
///   │ barcode    │        │  │ barcode      │  ₪original  │  (strikethrough)
///   ├────────────┼────────┤  ├──────────────┼────────────┤
///   │ chips      │ ₪final │  │ «label»      │  -₪discount │
///   └────────────┴────────┘  ├──────────────┼────────────┤
///                            │ chips        │  ₪final     │
///                            └──────────────┴────────────┘
///
/// The chips always sit on the final-price row; the barcode pairs with the
/// original price. Only bare amounts live in the price column. The discount
/// *label* sits at the start (image side) of the left column, vertically
/// centered against its value.
class _DetailsPriceGrid extends ConsumerWidget {
  const _DetailsPriceGrid({
    required this.item,
    required this.fmt,
    required this.barcode,
    required this.chips,
  });

  final CartItem item;
  final CurrencyFormat fmt;
  final Widget barcode;
  final Widget chips;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final product = item.product;

    final session = ref.watch(sessionControllerProvider);
    final memberSaves = session.memberSavingsFor(item);
    final effectivePrice = session.effectivePriceFor(item);
    final hasMemberDiscount = memberSaves > 0.005;

    final priceTextStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      color: scheme.primary,
      fontWeight: FontWeight.w800,
      height: 1.0,
      letterSpacing: -0.5,
    );
    final discountLabelStyle = Theme.of(context).textTheme.labelMedium
        ?.copyWith(
          color: scheme.error,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          height: 1.0,
        );
    final discountAmountStyle = Theme.of(context).textTheme.titleMedium
        ?.copyWith(color: scheme.error, fontWeight: FontWeight.w700);
    final strikeStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.lineThrough,
    );

    // Discount context, if any (sale takes precedence over member pricing).
    final ({String label, double from, double savings, double to})? discount;
    if (product.isOnSale) {
      discount = (
        label: l10n.saleDiscountShort.toUpperCase(),
        from: product.originalPrice,
        savings: product.originalPrice - product.price,
        to: product.price,
      );
    } else if (hasMemberDiscount) {
      discount = (
        label: l10n.memberDiscountShort.toUpperCase(),
        from: product.price,
        savings: memberSaves,
        to: effectivePrice,
      );
    } else {
      discount = null;
    }

    // A row of the outer two-column Table. Column 0 is flexible and absorbs all
    // slack, pushing the intrinsic price column flush against the card's trailing
    // border (the far side from the product name — the left edge in RTL): the
    // price block hugs that outer edge.
    TableRow priceRow(
      Widget left,
      Widget right, {
      TableCellVerticalAlignment valign = TableCellVerticalAlignment.bottom,
    }) => TableRow(
      children: [
        TableCell(
          verticalAlignment: valign,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: KioskTokens.spaceS),
            child: left,
          ),
        ),
        TableCell(verticalAlignment: valign, child: right),
      ],
    );

    // The emphasized final price, left-aligned so its ₪ sits on the card border
    // like the bottom totals panel's total.
    Widget finalPrice(String text) => Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Currency.amount(text, style: priceTextStyle),
      ),
    );

    // A spacer row that adds vertical breathing room between two price rows.
    TableRow gap(double height) => TableRow(
      children: [
        SizedBox(height: height),
        const SizedBox.shrink(),
      ],
    );

    final List<TableRow> tableRows;
    if (discount != null) {
      // The strike-through original and the discount share one font. Render each
      // with [Currency.decimalAligned]: the whole part (`₪65`, `-₪20`) is right-
      // aligned inside a shared-width slot and the `.00` follows, so both rows'
      // decimal points land on the same vertical axis — dot below dot — no matter
      // how many integer digits each has. The slot width is the widest of the two
      // whole parts, measured with the actual text styles. The big final price is
      // border-anchored on its own row below.
      final originalParts = fmt.formatParts(discount.from);
      final savingsParts = fmt.formatParts(discount.savings, signed: true);
      final wholeSlot = math.max(
        Currency.measureWidth(originalParts.whole, strikeStyle),
        Currency.measureWidth(savingsParts.whole, discountAmountStyle),
      );
      tableRows = [
        priceRow(
          barcode,
          Currency.decimalAligned(
            originalParts,
            style: strikeStyle,
            wholeSlot: wholeSlot,
          ),
        ),
        gap(2),
        priceRow(
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              discount.label,
              style: discountLabelStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Currency.decimalAligned(
            savingsParts,
            style: discountAmountStyle,
            wholeSlot: wholeSlot,
          ),
          valign: TableCellVerticalAlignment.middle,
        ),
        gap(KioskTokens.spaceS),
        priceRow(chips, finalPrice(fmt.format(discount.to))),
      ];
    } else {
      tableRows = [
        priceRow(barcode, const SizedBox.shrink()),
        gap(KioskTokens.spaceS),
        priceRow(chips, finalPrice(fmt.format(product.price))),
      ];
    }

    return Table(
      columnWidths: const {0: FlexColumnWidth(), 1: IntrinsicColumnWidth()},
      defaultVerticalAlignment: TableCellVerticalAlignment.bottom,
      children: tableRows,
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({
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

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: scheme.primaryContainer),
        if (imageUrl.isNotEmpty)
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.4),
                  ),
                ),
              );
            },
            errorBuilder: (_, _, _) => Center(
              child: Icon(
                productFallbackIcon(category, subCategory),
                size: 48,
                color: scheme.onPrimaryContainer,
              ),
            ),
          )
        else
          Center(
            child: Icon(
              productFallbackIcon(category, subCategory),
              size: 48,
              color: scheme.onPrimaryContainer,
            ),
          ),
      ],
    );
  }
}

/// A single-line, horizontally scrollable row of attribute chips.
///
/// The chips never wrap (so the card keeps its fixed height) and never paint
/// over the neighbouring price column: the row is hard-clipped to its own box
/// and its trailing edge fades out, signalling "swipe for more" while keeping
/// clear of the price. Trailing padding keeps the last visible chip off the
/// price when the row happens to fit exactly.
class _FadingChipRow extends StatelessWidget {
  const _FadingChipRow({required this.children});

  final List<Widget> children;

  /// Width of the trailing fade, in logical pixels.
  static const double _fadeWidth = 24.0;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      // The mask multiplies the child's alpha, so we only need the alpha
      // channel of these colours to matter — opaque = keep, transparent = fade.
      shaderCallback: (bounds) {
        // Opaque across the whole row, fading to transparent only over the
        // last `_fadeWidth` pixels. If the row is narrower than the fade, keep
        // it fully opaque so short rows aren't dimmed.
        final fadeStop = bounds.width <= _fadeWidth
            ? 1.0
            : 1.0 - (_fadeWidth / bounds.width);
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [Colors.white, Colors.white, Colors.transparent],
          stops: [0.0, fadeStop, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height));
      },
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.hardEdge,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.only(end: _fadeWidth),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: KioskTokens.spaceXS),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, this.swatchColor});
  final IconData icon;
  final String label;
  final Color? swatchColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (swatchColor != null) ...[
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: swatchColor,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outlineVariant, width: 1),
              ),
            ),
            const SizedBox(width: 6),
          ] else ...[
            Icon(icon, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

IconData productFallbackIcon(String category, String subCategory) {
  final sub = subCategory.toLowerCase();
  if (sub.contains('jean')) return Icons.checkroom_outlined;
  if (sub.contains('shirt') || sub.contains('tee')) {
    return Icons.dry_cleaning_outlined;
  }
  if (sub.contains('dress')) return Icons.woman_2_outlined;
  if (sub.contains('jacket') || sub.contains('coat')) {
    return Icons.dry_cleaning_outlined;
  }
  if (sub.contains('sneaker') || sub.contains('shoe') || sub.contains('boot')) {
    return Icons.hiking_outlined;
  }
  if (sub.contains('scarf') || sub.contains('hat') || sub.contains('belt')) {
    return Icons.diamond_outlined;
  }
  return switch (category.toLowerCase()) {
    'apparel' => Icons.checkroom_outlined,
    'footwear' => Icons.hiking_outlined,
    'accessories' => Icons.diamond_outlined,
    _ => Icons.shopping_bag_outlined,
  };
}
