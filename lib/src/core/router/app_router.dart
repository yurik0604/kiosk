import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_controller.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/catalog/presentation/catalog_screen.dart';
import '../../features/checkout/checkout_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/kiosk/data/kiosk_controller.dart';
import '../../features/kiosk/domain/kiosk_state.dart';
import '../../features/kiosk/presentation/kiosk_not_defined_screen.dart';
import '../../features/rfid/presentation/reader_settings_screen.dart';
import '../../features/session/presentation/session_screen.dart';
import '../../features/splash/splash_screen.dart';

abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const kioskNotDefined = '/kiosk-not-defined';
  static const session = '/session';
  static const checkout = '/checkout';
  static const catalog = '/catalog';
  static const readerSettings = '/admin/reader';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterRefresh(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final kiosk = ref.read(kioskControllerProvider);
      final loc = state.matchedLocation;

      // Splash owns the initial bootstrap; never redirect away from it.
      if (loc == AppRoutes.splash) return null;
      if (!auth.isResolved) return null;

      final isLoginRoute = loc == AppRoutes.login;
      final isKioskNotDefined = loc == AppRoutes.kioskNotDefined;

      // 1) Not authenticated → login is the only place allowed.
      if (!auth.isAuthenticated) {
        return isLoginRoute ? null : AppRoutes.login;
      }

      // 2) Authenticated. Kiosk data is a HARD entry requirement: the user
      // cannot proceed past login until the kiosk resolves. Gate on kiosk
      // readiness, not just authentication.
      if (!kiosk.isReady) {
        // Still resolving (loading / not-yet-started): hold on the current
        // gating screen — don't flash home. Splash/login/not-defined are the
        // only valid holding spots while the gate is in flight.
        if (kiosk.isLoading || kiosk.status == KioskStatus.unknown) {
          return (isLoginRoute || isKioskNotDefined) ? null : AppRoutes.login;
        }
        // Kiosk failed to resolve (404 / error) → block on the not-defined
        // screen. Its Close button signs out, which drops to rule (1).
        return isKioskNotDefined ? null : AppRoutes.kioskNotDefined;
      }

      // 3) Authenticated AND kiosk ready → the app is unlocked. Bounce off the
      // gating screens into home; allow every other route.
      if (isLoginRoute || isKioskNotDefined) {
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
        path: AppRoutes.kioskNotDefined,
        pageBuilder: (_, st) => _fade(st, const KioskNotDefinedScreen()),
      ),
      GoRoute(
        path: AppRoutes.session,
        pageBuilder: (_, st) => _slide(st, const SessionScreen()),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        pageBuilder: (_, st) => _slide(st, const CheckoutScreen()),
      ),
      GoRoute(
        path: AppRoutes.catalog,
        pageBuilder: (_, st) => _slide(st, const CatalogScreen()),
      ),
      GoRoute(
        path: AppRoutes.readerSettings,
        pageBuilder: (_, st) => _slide(st, const ReaderSettingsScreen()),
      ),
    ],
  );
});

/// Refreshes the router when auth OR kiosk state changes. Kiosk readiness is a
/// gating condition in [redirect], so the router must re-evaluate when the kiosk
/// gate resolves (e.g. loading → ready / error), not only on auth changes.
class _AuthRouterRefresh extends ChangeNotifier {
  _AuthRouterRefresh(this._ref) {
    _authSub = _ref.listen<AuthStateData>(
      authControllerProvider,
      (prev, next) => notifyListeners(),
      fireImmediately: false,
    );
    _kioskSub = _ref.listen<KioskStateData>(
      kioskControllerProvider,
      (prev, next) => notifyListeners(),
      fireImmediately: false,
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AuthStateData> _authSub;
  late final ProviderSubscription<KioskStateData> _kioskSub;

  @override
  void dispose() {
    _authSub.close();
    _kioskSub.close();
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
