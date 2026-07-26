import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/auth_user.dart';
import '../domain/token_data.dart';
import 'secure_storage.dart';

final _log = AppLogger.instance;

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class LoginResult {
  const LoginResult({required this.token, required this.user});
  final TokenData token;
  final AuthUser user;
}

class AuthService {
  AuthService({SecureStorage? storage, http.Client? httpClient})
      : _storage = storage ?? SecureStorage(),
        _client = httpClient ?? http.Client();

  final SecureStorage _storage;
  final http.Client _client;

  Future<TokenData?> readToken() async {
    final raw = await _storage.read(AppConfig.tokenStorageKey);
    if (raw == null) return null;
    try {
      return TokenData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await _storage.delete(AppConfig.tokenStorageKey);
      return null;
    }
  }

  Future<AuthUser?> readUser() async {
    final raw = await _storage.read(AppConfig.userStorageKey);
    if (raw == null) return null;
    try {
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await _storage.delete(AppConfig.userStorageKey);
      return null;
    }
  }

  Future<void> _saveSession(TokenData token, AuthUser user) async {
    await _storage.write(
      AppConfig.tokenStorageKey,
      jsonEncode(token.toJson()),
    );
    await _storage.write(
      AppConfig.userStorageKey,
      jsonEncode(user.toJson()),
    );
  }

  Future<void> clearSession() async {
    await _storage.delete(AppConfig.tokenStorageKey);
    await _storage.delete(AppConfig.userStorageKey);
  }

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse(AppConfig.apiUrl(AppConfig.loginEndpoint));
    _log.i('POST $url (email=$email)');

    final http.Response response;
    try {
      response = await _client
          .post(
            url,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(AppConfig.apiTimeout);
    } on TimeoutException catch (e, st) {
      _log.e('Login timeout', error: e, stackTrace: st);
      throw AuthException(
        'Connection timeout. Please check your network and try again.',
      );
    } on http.ClientException catch (e, st) {
      _log.e('Login network error: ${e.message}', error: e, stackTrace: st);
      throw AuthException(
        'Unable to reach the server. Please check your connection.',
      );
    } catch (e, st) {
      _log.e('Login unexpected error', error: e, stackTrace: st);
      rethrow;
    }

    _log.d('Login response: status=${response.statusCode} '
        'len=${response.contentLength ?? response.body.length} '
        'content-type=${response.headers['content-type']}');

    Map<String, dynamic>? body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException catch (e) {
      _log.w('Login response not JSON: ${e.message} — '
          'body preview: ${_preview(response.body)}');
    }

    if (response.statusCode == 200 && body != null) {
      final token = TokenData.fromJson(body);
      if (token.isEmpty) {
        _log.e('Login 200 but token missing in body keys=${body.keys.toList()}');
        throw AuthException('Server returned an invalid login response.');
      }
      final userJson = body['user'];
      final user = userJson is Map<String, dynamic>
          ? AuthUser.fromJson(userJson)
          : AuthUser(
              id: 0,
              username: email,
              email: email,
            );
      await _saveSession(token, user);
      _log.i('Login OK for ${user.email}');
      return LoginResult(token: token, user: user);
    }

    if (response.statusCode == 401 || response.statusCode == 400) {
      final detail = body?['detail']?.toString() ??
          body?['error']?.toString() ??
          'Invalid email or password.';
      _log.w('Login rejected (${response.statusCode}): $detail');
      throw AuthException(detail);
    }

    _log.e('Login failed status=${response.statusCode} '
        'body=${_preview(response.body)}');
    throw AuthException(
      'Unable to sign in (status ${response.statusCode}). Please try again.',
    );
  }

  static String _preview(String body, {int max = 300}) =>
      body.length <= max ? body : '${body.substring(0, max)}…';

  /// Fetch the full current user from `/v1/users/me/` (Bearer auth, no tenant
  /// slug). This is the only source of `customer_group_ids` and `tenant_slug` —
  /// the login token response doesn't include them. On success the stored
  /// session user is updated so group/catalog init can resolve the group.
  ///
  /// Returns the fetched user, or null on any failure (non-fatal).
  Future<AuthUser?> fetchCurrentUser() async {
    final token = await readToken();
    if (token == null || token.isEmpty) return null;

    final url = Uri.parse(AppConfig.apiUrl(AppConfig.currentUserEndpoint));
    try {
      final response = await _client.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${token.accessToken}',
        },
      ).timeout(AppConfig.apiTimeout);

      if (response.statusCode != 200) {
        _log.w('fetchCurrentUser: HTTP ${response.statusCode}');
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      // Support both a bare user object and an {status, data} envelope.
      final Map<String, dynamic> userJson =
          (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>)
              ? decoded['data'] as Map<String, dynamic>
              : decoded;

      final user = AuthUser.fromJson(userJson);
      // Persist so validateSession()/readUser() return the enriched user.
      await _storage.write(
        AppConfig.userStorageKey,
        jsonEncode(user.toJson()),
      );
      _log.i('fetchCurrentUser: ${user.email} '
          'groups=${user.customerGroupIds} slug=${user.tenantSlug}');
      return user;
    } on TimeoutException {
      _log.w('fetchCurrentUser: timeout');
      return null;
    } on http.ClientException catch (e) {
      _log.w('fetchCurrentUser: network error ${e.message}');
      return null;
    } catch (e, st) {
      _log.e('fetchCurrentUser: unexpected error', error: e, stackTrace: st);
      return null;
    }
  }

  Future<AuthUser?> validateSession() async {
    final token = await readToken();
    if (token == null || token.isEmpty) return null;
    return readUser();
  }

  Future<void> logout() => clearSession();
}
