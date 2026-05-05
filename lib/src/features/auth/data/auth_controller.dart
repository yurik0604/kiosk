import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      state = user != null
          ? AuthStateData.authenticated(user)
          : const AuthStateData.unauthenticated();
    } catch (_) {
      state = const AuthStateData.unauthenticated();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = const AuthStateData.authenticating();
    try {
      final result = await _service.login(email: email, password: password);
      state = AuthStateData.authenticated(result.user);
      return true;
    } on AuthException catch (e) {
      state = AuthStateData.error(e.message);
      return false;
    } catch (e) {
      state = AuthStateData.error('Unexpected error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _service.logout();
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
