import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_controller.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/checkout/checkout_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/session/presentation/session_screen.dart';
import '../../features/splash/splash_screen.dart';

abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const session = '/session';
  static const checkout = '/checkout';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterRefresh(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      if (loc == AppRoutes.splash) return null;
      if (!auth.isResolved) return null;

      final isLoginRoute = loc == AppRoutes.login;
      if (!auth.isAuthenticated && !isLoginRoute) {
        return AppRoutes.login;
      }
      if (auth.isAuthenticated && isLoginRoute) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (_, st) => _fade(st, const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (_, st) => _fade(st, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (_, st) => _fade(st, const HomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.session,
        pageBuilder: (_, st) => _slide(st, const SessionScreen()),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        pageBuilder: (_, st) => _slide(st, const CheckoutScreen()),
      ),
    ],
  );
});

class _AuthRouterRefresh extends ChangeNotifier {
  _AuthRouterRefresh(this._ref) {
    _sub = _ref.listen<AuthStateData>(
      authControllerProvider,
      (prev, next) => notifyListeners(),
      fireImmediately: false,
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AuthStateData> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 450),
    transitionsBuilder: (context, animation, secondary, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

CustomTransitionPage<void> _slide(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 360),
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}
