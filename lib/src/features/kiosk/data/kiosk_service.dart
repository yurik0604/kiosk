import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/authed_api_client.dart';
import '../domain/kiosk.dart';

final _log = AppLogger.instance;

final kioskServiceProvider = Provider<KioskService>((ref) {
  return KioskService(ref.read(authedApiClientProvider));
});

/// Thrown when the kiosk cannot be resolved for the device. [notDefined] is true
/// Why the kiosk couldn't be resolved. Drives which message the blocked screen
/// shows.
enum KioskFailureReason {
  /// HTTP 404 — the server is reachable but no kiosk is assigned to this user.
  notDefined,

  /// The server responded, but with an error status (e.g. 500 / 403). The
  /// server IS reachable — do NOT tell the user it's unreachable.
  serverError,

  /// No response at all — network failure or timeout. The server could not be
  /// reached.
  network,
}

/// Thrown when the kiosk cannot be resolved for the device. [reason]
/// distinguishes "not assigned to this user" (404) from a server error vs. an
/// unreachable server, so the UI can show an accurate message. Callers gate the
/// home screen on any of these.
class KioskUnavailableException implements Exception {
  const KioskUnavailableException(this.message, {required this.reason});

  final String message;
  final KioskFailureReason reason;

  /// True only for the definitive "no kiosk for this user" case (HTTP 404).
  bool get notDefined => reason == KioskFailureReason.notDefined;

  @override
  String toString() => 'KioskUnavailableException($reason: $message)';
}

class KioskService {
  KioskService(this._api);

  final AuthedApiClient _api;

  /// Fetch the device's kiosk from `GET v1/kiosks/me/`.
  ///
  /// The kiosk is bound to the authenticated user (each user backs at most one
  /// kiosk), so the backend resolves it from the bearer token — no id/query
  /// param needed. Returns the single kiosk on 200.
  ///
  /// Throws [KioskUnavailableException] with a [KioskFailureReason]:
  /// - [KioskFailureReason.notDefined] on HTTP 404 (no kiosk for this user).
  /// - [KioskFailureReason.serverError] on any other non-200 (the server IS
  ///   reachable, it just errored — e.g. 500 / 403).
  /// - [KioskFailureReason.network] on a network failure / timeout (no response).
  Future<Kiosk> fetchMyKiosk({required String? tenantSlug}) async {
    final http.Response response;
    try {
      response = await _api.get(
        AppConfig.kioskMeEndpoint,
        tenantSlug: tenantSlug,
      );
    } catch (e, st) {
      _log.e('fetchMyKiosk network error', error: e, stackTrace: st);
      throw KioskUnavailableException(
        'Network error: $e',
        reason: KioskFailureReason.network,
      );
    }

    // A 404 means the server is reachable but no kiosk is configured for the
    // current user — a definitive "not available for this user" (NOT transient).
    // Also treat a standardized NOT_FOUND envelope as not-defined in case a
    // proxy/middleware rewrites the transport status.
    if (response.statusCode == 404 || _isNotFoundEnvelope(response.body)) {
      _log.w('fetchMyKiosk: not found — no kiosk for the current user '
          '(HTTP ${response.statusCode})');
      throw const KioskUnavailableException(
        'The kiosk app is not available for this user.',
        reason: KioskFailureReason.notDefined,
      );
    }

    if (response.statusCode != 200) {
      _log.w('fetchMyKiosk HTTP ${response.statusCode}: ${response.body}');
      throw KioskUnavailableException(
        'Failed to fetch kiosk: HTTP ${response.statusCode}',
        reason: KioskFailureReason.serverError,
      );
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      _log.w('fetchMyKiosk: malformed response body: $e');
      throw KioskUnavailableException(
        'Malformed kiosk response: $e',
        reason: KioskFailureReason.serverError,
      );
    }

    final kiosk = Kiosk.fromJson(json);
    _log.i('fetchMyKiosk: resolved kiosk ${kiosk.id} (${kiosk.slug})');
    return kiosk;
  }

  /// True when [body] is the backend's standardized not-found error envelope
  /// (`{"code": "NOT_FOUND", ...}`). A defensive fallback for the rare case a
  /// proxy alters the transport status but preserves the JSON envelope.
  static bool _isNotFoundEnvelope(String body) {
    if (body.isEmpty) return false;
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> &&
          decoded['code'] == 'NOT_FOUND';
    } catch (_) {
      return false;
    }
  }
}
