import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../catalog/domain/barcode.dart';
import '../../catalog/domain/product.dart';
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
      heightFactor: 0.9,
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
                          top: 12,
                          start: 0,
                          end: 0,
                          child: Center(
                            child: Container(
                              width: 48,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(3),
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
                        product: p,
                        fmt: fmt,
                        l10n: l10n,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _Actions(
              onRemove: () {
                HapticFeedback.mediumImpact();
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
    required this.product,
    required this.fmt,
    required this.l10n,
  });

  final Product product;
  final NumberFormat fmt;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
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
        const SizedBox(height: 6),
        Text(
          product.name,
          style: Theme.of(context).textTheme.headlineLarge,
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
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      ean.formatted,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
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
        const SizedBox(height: KioskTokens.spaceM),
        _PriceBlock(product: product, fmt: fmt),
        const SizedBox(height: KioskTokens.spaceM),
        Wrap(
          spacing: KioskTokens.spaceXS,
          runSpacing: KioskTokens.spaceXS,
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
        Divider(color: scheme.outlineVariant, height: 1),
        const SizedBox(height: KioskTokens.spaceL),
        Text(
          product.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface,
                height: 1.55,
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

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.product, required this.fmt});
  final Product product;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          fmt.format(product.price),
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: scheme.primary,
                fontSize: 40,
                fontWeight: FontWeight.w700,
                height: 1.0,
                letterSpacing: -0.8,
              ),
        ),
        if (product.isOnSale) ...[
          const SizedBox(width: KioskTokens.spaceS),
          Text(
            fmt.format(product.originalPrice),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  decoration: TextDecoration.lineThrough,
                ),
          ),
          const SizedBox(width: KioskTokens.spaceXS),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KioskTokens.radiusSmall),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (swatchColor != null) ...[
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: swatchColor,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outlineVariant, width: 1),
              ),
            ),
            const SizedBox(width: 8),
          ] else ...[
            Icon(icon, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w500,
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
                fontSize: 11,
                letterSpacing: 1.6,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface,
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

    return Container(
      padding: EdgeInsets.fromLTRB(
        KioskTokens.spaceL,
        KioskTokens.spaceM,
        KioskTokens.spaceL,
        MediaQuery.viewPaddingOf(context).bottom + KioskTokens.spaceM,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: KioskTokens.touchTargetLarge,
            height: KioskTokens.touchTargetLarge,
            child: OutlinedButton(
              onPressed: onRemove,
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error, width: 1.5),
                padding: EdgeInsets.zero,
              ),
              child: Tooltip(
                message: l10n.removeFromBag,
                child: const Icon(Icons.delete_outline_rounded),
              ),
            ),
          ),
          const SizedBox(width: KioskTokens.spaceS),
          Expanded(
            child: FilledButton.icon(
              onPressed: onClose,
              icon: const Icon(Icons.check_rounded),
              label: Text(l10n.keepShopping),
            ),
          ),
        ],
      ),
    );
  }
}
