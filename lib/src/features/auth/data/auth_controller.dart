import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/data/catalog_sync_controller.dart';
import '../../group/data/group_controller.dart';
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

  Future<void> bootstrap() async {
    state = const AuthStateData.authenticating();
    try {
      final user = await _service
          .validateSession()
          .timeout(const Duration(seconds: 5));
      if (user != null) {
        state = AuthStateData.authenticated(user);
        _onAuthenticated();
      } else {
        state = const AuthStateData.unauthenticated();
      }
    } catch (_) {
      state = const AuthStateData.unauthenticated();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = const AuthStateData.authenticating();
    try {
      final result = await _service.login(email: email, password: password);
      state = AuthStateData.authenticated(result.user);
      _onAuthenticated();
      return true;
    } on AuthException catch (e) {
      state = AuthStateData.error(e.message);
      return false;
    } catch (e) {
      state = AuthStateData.error('Unexpected error: $e');
      return false;
    }
  }

  /// Fetch the full user, then initialize the device's group and catalog after
  /// authentication.
  ///
  /// The login token response does NOT include `customer_group_ids` /
  /// `tenant_slug`, so we first hydrate the user from `/v1/users/me/` (the same
  /// source the app uses). Group resolution + tenant-routed catalog calls depend
  /// on those fields, so this must run before group/catalog init.
  ///
  /// Fire-and-forget so navigation (splash → home / login → home) is never
  /// blocked, mirroring how `main()` fires the RFID reader bootstrap.
  void _onAuthenticated() {
    unawaited(() async {
      try {
        // Hydrate the user with group ids + tenant slug.
        final fullUser = await _service.fetchCurrentUser();
        if (fullUser != null) {
          state = AuthStateData.authenticated(fullUser);
        }
        // Group first so the catalog controller has a group id to sync against.
        await ref.read(groupControllerProvider.notifier).initialize();
        await ref
            .read(catalogSyncControllerProvider.notifier)
            .initializeCatalog();
      } catch (_) {
        // Non-fatal: the app still works without a synced catalog.
      }
    }());
  }

  Future<void> logout() async {
    await _service.logout();
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
