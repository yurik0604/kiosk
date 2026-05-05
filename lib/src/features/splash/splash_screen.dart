import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/data/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.microtask(() {});
    if (!mounted) return;
    final minimumSplash =
        Future<void>.delayed(const Duration(milliseconds: 1600));
    await ref.read(authControllerProvider.notifier).bootstrap();
    await minimumSplash;
    if (!mounted) return;
    final auth = ref.read(authControllerProvider);
    context.go(auth.isAuthenticated ? AppRoutes.home : AppRoutes.login);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    );
    final scaleIn = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer,
              scheme.surface,
              scheme.secondaryContainer,
            ],
            stops: const [0, 0.5, 1],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Opacity(
              opacity: fadeIn.value,
              child: Transform.scale(
                scale: scaleIn.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LogoMark(color: scheme.primary),
                    const SizedBox(height: KioskTokens.spaceL),
                    Text(
                      AppLocalizations.of(context).appName,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: KioskTokens.spaceXS),
                    Text(
                      AppLocalizations.of(context).splashTagline,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: scheme.secondary,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 3,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(KioskTokens.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Icon(
        Icons.checkroom_rounded,
        size: 88,
        color: Colors.white,
      ),
    );
  }
}
