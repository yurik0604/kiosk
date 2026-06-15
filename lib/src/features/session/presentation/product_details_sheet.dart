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
        _PriceBlock(product: product, fmt: fmt, l10n: l10n),
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

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({
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
    final savings = product.originalPrice - product.price;
    return Container(
      padding: const EdgeInsets.all(KioskTokens.spaceM),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KioskTokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (product.isOnSale) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  l10n.subtotal,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  fmt.format(product.originalPrice),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.lineThrough,
                      ),
                ),
              ],
            ),
            const SizedBox(height: KioskTokens.spaceXS),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  l10n.youSavedLabel,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '-${fmt.format(savings)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: KioskTokens.spaceS),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                l10n.total,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                fmt.format(product.price),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
            ],
          ),
        ],
      ),
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
            child: FilledButton(
              onPressed: onRemove,
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
              ),
              child: Tooltip(
                message: l10n.removeFromBag,
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: KioskTokens.spaceS),
          Expanded(
            child: FilledButton.icon(
              onPressed: onClose,
              icon: const Icon(
                Icons.check_rounded,
                size: 28,
                color: Colors.white,
              ),
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
          ),
        ],
      ),
    );
  }
}
