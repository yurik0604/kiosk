import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/data/catalog_sync_controller.dart';
import '../../group/data/group_controller.dart';
import '../../kiosk/data/kiosk_controller.dart';
import '../domain/auth_state.dart';
import 'auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final service = AuthService();
  ref.onDispose(() {});
  return service;
});

class AuthController extends Notifier<AuthStateData> {
  @override
  AuthStateData build() => const AuthStateData.unknown();

  AuthService get _service => ref.read(authServiceProvider);

  /// Restore a prior session. Returns `true` only when the user is authenticated
  /// AND the device's kiosk is ready (the loading gate); `false` otherwise, so
  /// the caller routes to login or the kiosk-not-defined screen accordingly.
  Future<bool> bootstrap() async {
    state = const AuthStateData.authenticating();
    try {
      final user = await _service
          .validateSession()
          .timeout(const Duration(seconds: 5));
      if (user != null) {
        state = AuthStateData.authenticated(user);
        return await _onAuthenticated();
      }
      state = const AuthStateData.unauthenticated();
      return false;
    } catch (_) {
      state = const AuthStateData.unauthenticated();
      return false;
    }
  }

  /// Log in. Returns `true` only when authentication succeeds AND the device's
  /// kiosk is ready (see [_onAuthenticated]). A `false` return with the state
  /// still `authenticated` means login worked but the kiosk is not defined — the
  /// caller must route to the kiosk-not-defined screen, not the home screen.
  Future<bool> login({required String email, required String password}) async {
    state = const AuthStateData.authenticating();
    try {
      final result = await _service.login(email: email, password: password);
      state = AuthStateData.authenticated(result.user);
      return await _onAuthenticated();
    } on AuthException catch (e) {
      state = AuthStateData.error(e.message);
      return false;
    } catch (e) {
      state = AuthStateData.error('Unexpected error: $e');
      return false;
    }
  }

  /// Post-authentication sequence, in order:
  ///
  ///   1. **Kiosk gate (blocking).** Using the login token, fetch
  ///      `kiosks/me/`. The kiosk model is essential — if it doesn't resolve
  ///      (404 / error) this returns `false` and the home screen must not open
  ///      (the router routes to the kiosk-not-defined screen). The tenant is
  ///      resolved from the JWT's tenant claim, and the login response already
  ///      carries `tenant_slug` for the URL, so this needs no prior `/me/` call.
  ///   2. **Hydrate the user (`/v1/users/me/`).** Only once the kiosk is
  ///      confirmed do we enrich the user with `customer_group_ids` /
  ///      `tenant_slug` — the data group/catalog resolution depends on.
  ///   3. **Group + catalog (best-effort, non-blocking).** Never gates
  ///      navigation; the app still works without a synced catalog.
  ///
  /// Returns `true` only when the kiosk resolved.
  Future<bool> _onAuthenticated() async {
    // 1) Blocking gate: no kiosk → not allowed past login.
    final kioskReady =
        await ref.read(kioskControllerProvider.notifier).initialize();
    if (!kioskReady) return false;

    // 2) Kiosk confirmed — hydrate the full user for group ids + tenant slug.
    try {
      final fullUser = await _service.fetchCurrentUser();
      if (fullUser != null) {
        state = AuthStateData.authenticated(fullUser);
      }
    } catch (_) {
      // Non-fatal: proceed with the login-provided user.
    }

    // 3) Best-effort, non-blocking: group + catalog.
    unawaited(() async {
      try {
        await ref.read(groupControllerProvider.notifier).initialize();
        await ref
            .read(catalogSyncControllerProvider.notifier)
            .initializeCatalog();
      } catch (_) {
        // Non-fatal: the app still works without a synced catalog.
      }
    }());

    return true;
  }

  Future<void> logout() async {
    await _service.logout();
    await ref.read(kioskControllerProvider.notifier).clear();
    await ref.read(groupControllerProvider.notifier).clear();
    await ref.read(catalogSyncControllerProvider.notifier).reset();
    state = const AuthStateData.unauthenticated();
  }

  void clearError() {
    if (state.status == AuthStatus.error) {
      state = const AuthStateData.unauthenticated();
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthStateData>(AuthController.new);
