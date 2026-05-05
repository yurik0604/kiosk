import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../catalog/domain/barcode.dart';
import '../../catalog/domain/product.dart';
import '../domain/cart_item.dart';
import 'product_details_sheet.dart';

const double _kCardHeight = 180;
const double _kImageWidth = 150;

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.item, required this.onRemove});

  final CartItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = NumberFormat.simpleCurrency(
      locale: Localizations.localeOf(context).toString(),
      name: 'ILS',
    );
    final p = item.product;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KioskTokens.radiusMedium),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            showProductDetailsSheet(
              context: context,
              item: item,
              onRemove: onRemove,
            );
          },
          child: SizedBox(
            height: _kCardHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProductImage(
                  imageUrl: p.imageUrl,
                  category: p.category,
                  subCategory: p.subCategory,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(KioskTokens.spaceM),
                    child: _ProductBody(product: p, fmt: fmt),
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

class _ProductBody extends StatelessWidget {
  const _ProductBody({required this.product, required this.fmt});
  final Product product;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.secondary,
                          fontSize: 12,
                          letterSpacing: 1.8,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 24,
                          height: 1.15,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Builder(
                    builder: (context) {
                      final ean = Ean13.fromSku(product.sku);
                      return Semantics(
                        label: l10n.barcodeLabel(ean.digits),
                        child: Row(
                          children: [
                            Icon(
                              Icons.qr_code_2_rounded,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                ean.formatted,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                      letterSpacing: 0.5,
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
                ],
              ),
              const SizedBox(height: KioskTokens.spaceXS),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _InfoChip(
                    icon: Icons.straighten_rounded,
                    label: product.size,
                  ),
                  _InfoChip(
                    icon: Icons.palette_outlined,
                    label: product.color,
                    swatchColor: _parseHex(product.colorHex),
                  ),
                  if (product.subCategory.isNotEmpty)
                    _InfoChip(
                      icon: Icons.category_outlined,
                      label: product.subCategory,
                    ),
                  _InfoChip(
                    icon: Icons.person_outline_rounded,
                    label: _localizedGender(l10n, product.gender),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: KioskTokens.spaceS),
        _PriceColumn(product: product, fmt: fmt),
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

class _PriceColumn extends StatelessWidget {
  const _PriceColumn({required this.product, required this.fmt});
  final Product product;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (product.isOnSale) ...[
          Text(
            fmt.format(product.originalPrice),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  decoration: TextDecoration.lineThrough,
                ),
          ),
          const SizedBox(height: 2),
        ],
        Text(
          fmt.format(product.price),
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
                height: 1.0,
                letterSpacing: -0.5,
              ),
        ),
        if (product.isOnSale) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '-${product.discountPct.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 12,
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
            ),
          ),
        ],
      ],
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

    return SizedBox(
      width: _kImageWidth,
      height: _kCardHeight,
      child: Stack(
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(KioskTokens.radiusSmall),
        border: Border.all(color: scheme.outlineVariant),
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
                  fontWeight: FontWeight.w500,
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
  if (sub.contains('sneaker') ||
      sub.contains('shoe') ||
      sub.contains('boot')) {
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
