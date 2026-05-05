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

  static const String tokenStorageKey = 'kiosk_token_data';
  static const String userStorageKey = 'kiosk_user_data';

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
