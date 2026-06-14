import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/locale/locale_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/data/auth_controller.dart';
import '../rfid/data/rfid_reader_controller.dart';
import '../rfid/domain/reader_status.dart';
import '../session/data/session_controller.dart';
import 'widgets/ad_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(KioskTokens.spaceL),
            child: Column(
              children: [
                _TopBar(
                  onLogout: () =>
                      ref.read(authControllerProvider.notifier).logout(),
                  onAdmin: () => context.push(AppRoutes.readerSettings),
                ),
                const SizedBox(height: KioskTokens.spaceL),
                const Expanded(flex: 2, child: _Hero()),
                const SizedBox(height: KioskTokens.spaceL),
                const Expanded(flex: 1, child: _AdCarousel()),
                const SizedBox(height: KioskTokens.spaceL),
                _StartSessionButton(
                  label: l10n.clickToStart,
                  onTap: () {
                    ref.read(sessionControllerProvider.notifier).reset();
                    context.go(AppRoutes.session);
                  },
                  color: scheme.primary,
                ),
                const SizedBox(height: KioskTokens.spaceL),
                const SizedBox(height: 64, child: _LanguageSwitcher()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.onLogout, required this.onAdmin});

  final VoidCallback onLogout;
  final VoidCallback onAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final readerStatus = ref.watch(
      rfidReaderControllerProvider.select((s) => s.status),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(KioskTokens.radiusMedium),
          ),
          child: Icon(
            Icons.checkroom_rounded,
            color: scheme.onPrimaryContainer,
            size: 32,
          ),
        ),
        const SizedBox(width: KioskTokens.spaceS),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 26,
                    ),
              ),
              Text(
                l10n.topBarSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.secondary,
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: KioskTokens.spaceS),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.wifi_rounded, color: scheme.onSurfaceVariant),
            const SizedBox(width: KioskTokens.spaceS),
            // Long-press the status pill to open admin reader settings.
            GestureDetector(
              onLongPress: onAdmin,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: KioskTokens.spaceS,
                  vertical: KioskTokens.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(KioskTokens.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _statusColor(readerStatus, scheme),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      readerStatus.isConnected ? l10n.online : 'OFFLINE',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontSize: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: KioskTokens.spaceS),
            Tooltip(
              message: l10n.logout,
              child: IconButton(
                onPressed: onLogout,
                icon: Icon(
                  Icons.logout_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _statusColor(ReaderStatus s, ColorScheme scheme) {
    switch (s) {
      case ReaderStatus.reading:
      case ReaderStatus.connected:
      case ReaderStatus.idle:
        return scheme.tertiary;
      case ReaderStatus.connecting:
        return scheme.secondary;
      case ReaderStatus.error:
        return scheme.error;
      case ReaderStatus.offline:
      case ReaderStatus.disconnected:
        return scheme.outline;
    }
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [scheme.primary, scheme.secondary],
        ),
        borderRadius: BorderRadius.circular(KioskTokens.radiusLarge),
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -40,
            bottom: -40,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          PositionedDirectional(
            end: 60,
            top: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(KioskTokens.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KioskTokens.spaceS,
                    vertical: KioskTokens.spaceXS,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius:
                        BorderRadius.circular(KioskTokens.radiusSmall),
                  ),
                  child: Text(
                    l10n.heroEyebrow,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 13,
                          letterSpacing: 2,
                        ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.heroTitle,
                      style: Theme.of(context)
                          .textTheme
                          .displayLarge
                          ?.copyWith(
                            color: Colors.white,
                            fontSize: 54,
                            height: 1.05,
                          ),
                    ),
                    const SizedBox(height: KioskTokens.spaceS),
                    Text(
                      l10n.heroSubtitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w400,
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StartSessionButton extends StatefulWidget {
  const _StartSessionButton({
    required this.onTap,
    required this.color,
    required this.label,
  });

  final VoidCallback onTap;
  final Color color;
  final String label;

  @override
  State<_StartSessionButton> createState() => _StartSessionButtonState();
}

class _StartSessionButtonState extends State<_StartSessionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = 0.25 + 0.15 * _pulse.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KioskTokens.radiusXLarge),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: glow),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: SizedBox(
        width: double.infinity,
        height: KioskTokens.touchTargetHero,
        child: FilledButton(
          onPressed: widget.onTap,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(KioskTokens.radiusXLarge),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.label.toUpperCase(),
              maxLines: 1,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdCarousel extends StatefulWidget {
  const _AdCarousel();

  @override
  State<_AdCarousel> createState() => _AdCarouselState();
}

class _AdCarouselState extends State<_AdCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      _index = (_index + 1) % 3;
      _controller.animateToPage(
        _index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ads = <AdItem>[
      AdItem(
        title: l10n.adFw26Title,
        subtitle: l10n.adFw26Subtitle,
        icon: Icons.local_offer_outlined,
        imageUrl:
            'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=1200&q=80',
      ),
      AdItem(
        title: l10n.adAlterationsTitle,
        subtitle: l10n.adAlterationsSubtitle,
        icon: Icons.content_cut_rounded,
        imageUrl:
            'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=1200&q=80',
      ),
      AdItem(
        title: l10n.adSpringTitle,
        subtitle: l10n.adSpringSubtitle,
        icon: Icons.auto_awesome_outlined,
        imageUrl:
            'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=1200&q=80',
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(KioskTokens.radiusLarge),
      child: PageView.builder(
        controller: _controller,
        itemCount: ads.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AdCard(ad: ads[i]),
        ),
      ),
    );
  }
}

class _LanguageSwitcher extends ConsumerWidget {
  const _LanguageSwitcher();

  static const _options = [
    (Locale('en'), 'EN', 'English'),
    (Locale('he'), 'עב', 'עברית'),
    (Locale('ar'), 'ع', 'العربية'),
    (Locale('ru'), 'RU', 'Русский'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final current = ref.watch(localeControllerProvider);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(KioskTokens.radiusLarge),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (locale, code, name) in _options)
              _LangChip(
                label: code,
                tooltip: name,
                selected: current.languageCode == locale.languageCode,
                onTap: () => ref
                    .read(localeControllerProvider.notifier)
                    .setLocale(locale),
              ),
          ],
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: AnimatedContainer(
        duration: KioskTokens.motionFast,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(KioskTokens.radiusMedium),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(KioskTokens.radiusMedium),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: KioskTokens.spaceM,
                vertical: 12,
              ),
              constraints: const BoxConstraints(minWidth: 56),
              alignment: Alignment.center,
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color:
                          selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
