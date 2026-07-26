import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  /// Build flavor: `local` or `prod`. Selected via `--dart-define=ENV=...`.
  static const String env =
      String.fromEnvironment('ENV', defaultValue: 'local');

  static String get envFile => '.env.$env';

  static String get baseUrl =>
      dotenv.maybeGet('BASE_URL') ?? 'http://localhost:8000';

  static const String loginEndpoint = 'auth/token/';

  /// Current-user endpoint. Tenant-agnostic (no slug in path). Returns the full
  /// user, including `customer_group_ids` and `tenant_slug`, which the login
  /// token response does not carry.
  static const String currentUserEndpoint = 'v1/users/me/';

  /// Group list endpoint (DRF paginated). The tenant slug is injected into the
  /// path by [AuthedApiClient].
  static const String groupsEndpoint = 'v1/groups/';

  /// Catalog endpoints are built per-group:
  ///   GET v1/groups/{id}/catalog/            → catalog metadata
  ///   GET v1/groups/{id}/catalog/download-url/ → presigned download info
  static String catalogEndpoint(int groupId) => 'v1/groups/$groupId/catalog/';
  static String catalogDownloadUrlEndpoint(int groupId) =>
      'v1/groups/$groupId/catalog/download-url/';

  static const String tokenStorageKey = 'kiosk_token_data';
  static const String userStorageKey = 'kiosk_user_data';

  /// Group data persisted across restarts.
  static const String groupStorageKey = 'kiosk_group_data';

  static Duration get apiTimeout => Duration(
        seconds:
            int.tryParse(dotenv.maybeGet('API_TIMEOUT_SECONDS') ?? '') ?? 15,
      );

  static String apiUrl(String path) {
    final base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final tail = path.startsWith('/') ? path.substring(1) : path;
    return '$base$tail';
  }
}
