import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/data/auth_controller.dart';
import '../../features/auth/data/auth_service.dart';
import '../config/app_config.dart';
import '../logging/app_logger.dart';

final _log = AppLogger.instance;

/// Shared tenant-aware authenticated HTTP client for group/catalog calls.
final authedApiClientProvider = Provider<AuthedApiClient>((ref) {
  return AuthedApiClient(authService: ref.read(authServiceProvider));
});

/// Tenant-aware authenticated HTTP helper for group/catalog API calls.
///
/// - [get] attaches a `Bearer` token (read from [AuthService]) and injects the
///   tenant slug into the URL path (path-based multi-tenant routing).
/// - [downloadFileToTempStreaming] streams a presigned S3 URL to a temp file
///   with NO auth header and NO slug (authentication is embedded in the URL).
///
/// The slug is passed per call (not stored globally) to keep this stateless.
class AuthedApiClient {
  AuthedApiClient({required AuthService authService, http.Client? client})
      : _authService = authService,
        _client = client ?? http.Client();

  final AuthService _authService;
  final http.Client _client;

  /// Endpoints that must NOT get the tenant slug prepended.
  static const List<String> _excludedEndpoints = [
    'v1/tenants',
    'auth/token',
    'v1/users/me',
  ];

  static bool _isExcluded(String url) =>
      _excludedEndpoints.any((e) => url.contains(e));

  /// Injects [tenantSlug] into the URL path, e.g.
  /// `http://host:8000/v1/groups/` → `http://host:8000/elsrad/v1/groups/`.
  /// Returns the URL unchanged when the slug is null/empty or the endpoint is
  /// excluded.
  static String buildTenantUrl(String url, String? tenantSlug) {
    if (tenantSlug == null || tenantSlug.isEmpty || _isExcluded(url)) {
      return url;
    }
    try {
      final uri = Uri.parse(url);
      return uri.replace(path: '/$tenantSlug${uri.path}').toString();
    } catch (e) {
      _log.w('buildTenantUrl failed for $url: $e');
      return url;
    }
  }

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final token = await _authService.readToken();
    final access = token?.accessToken;
    if (access != null && access.isNotEmpty) {
      headers['Authorization'] = 'Bearer $access';
    }
    return headers;
  }

  /// Authenticated GET. [path] is a relative API path (joined with the base URL
  /// via [AppConfig.apiUrl]) or an absolute URL.
  Future<http.Response> get(
    String path, {
    String? tenantSlug,
    Duration? timeout,
  }) async {
    final base =
        path.startsWith('http') ? path : AppConfig.apiUrl(path);
    final url = buildTenantUrl(base, tenantSlug);
    _log.d('GET $url');
    return _client
        .get(Uri.parse(url), headers: await _headers())
        .timeout(timeout ?? AppConfig.apiTimeout);
  }

  /// Downloads a file directly to disk via streaming — no full-memory buffering.
  ///
  /// For presigned S3 URLs: skips auth headers and tenant slug since auth is
  /// embedded in the URL query parameters. [expectedFileSize] is used for
  /// accurate progress when the response Content-Length is unavailable.
  Future<String> downloadFileToTempStreaming(
    String url, {
    String? fileName,
    int? expectedFileSize,
    Duration? timeout,
    void Function(int received, int total)? onProgress,
  }) async {
    final request = http.Request('GET', Uri.parse(url));
    // No auth headers — presigned S3 URLs authenticate via query params.

    final streamedResponse = await request
        .send()
        .timeout(timeout ?? const Duration(minutes: 10));

    if (streamedResponse.statusCode != 200) {
      throw Exception('Download failed: HTTP ${streamedResponse.statusCode}');
    }

    final total = expectedFileSize ?? streamedResponse.contentLength ?? 0;
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/${fileName ?? 'download.tmp'}');
    final sink = file.openWrite();

    var received = 0;
    await for (final chunk in streamedResponse.stream) {
      sink.add(chunk);
      received += chunk.length;
      onProgress?.call(received, total);
    }

    await sink.flush();
    await sink.close();

    return file.path;
  }
}
