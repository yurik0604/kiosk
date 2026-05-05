import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AdItem {
  const AdItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.imageUrl,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? imageUrl;
}

class AdCard extends StatelessWidget {
  const AdCard({super.key, required this.ad});

  final AdItem ad;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasImage = ad.imageUrl != null;
    final radius = BorderRadius.circular(KioskTokens.radiusLarge);

    final titleColor = hasImage ? Colors.white : scheme.onTertiaryContainer;
    final subtitleColor = hasImage
        ? Colors.white.withValues(alpha: 0.9)
        : scheme.onTertiaryContainer.withValues(alpha: 0.8);

    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: scheme.tertiaryContainer),
          if (hasImage)
            Image.network(
              ad.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const SizedBox.shrink();
              },
            ),
          if (hasImage)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.5, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
          PositionedDirectional(
            top: KioskTokens.spaceM,
            start: KioskTokens.spaceM,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hasImage
                    ? Colors.white.withValues(alpha: 0.18)
                    : scheme.tertiary,
                borderRadius: BorderRadius.circular(KioskTokens.radiusSmall),
                border: hasImage
                    ? Border.all(color: Colors.white.withValues(alpha: 0.4))
                    : null,
              ),
              child: Icon(
                ad.icon,
                color: hasImage ? Colors.white : scheme.onTertiary,
                size: 22,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(KioskTokens.spaceL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        letterSpacing: -0.2,
                      ),
                ),
                const SizedBox(height: KioskTokens.spaceXS),
                Text(
                  ad.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: subtitleColor,
                        fontWeight: FontWeight.w400,
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
