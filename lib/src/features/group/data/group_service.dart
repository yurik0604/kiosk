import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/authed_api_client.dart';
import '../domain/group.dart';

final _log = AppLogger.instance;

final groupServiceProvider = Provider<GroupService>((ref) {
  return GroupService(ref.read(authedApiClientProvider));
});

class GroupService {
  GroupService(this._api);

  final AuthedApiClient _api;

  /// Fetch the group for the device from `GET v1/groups/` (DRF paginated),
  /// returning the group matching [groupId], or the first result as a fallback
  /// (a single-group device typically has exactly one).
  ///
  /// The kiosk keeps only the root fields + `group_settings` (see [Group]).
  Future<Group?> fetchGroup({
    required int groupId,
    required String? tenantSlug,
  }) async {
    final http.Response response;
    try {
      response = await _api.get(
        AppConfig.groupsEndpoint,
        tenantSlug: tenantSlug,
      );
    } catch (e, st) {
      _log.e('fetchGroup network error', error: e, stackTrace: st);
      rethrow;
    }

    if (response.statusCode != 200) {
      _log.w('fetchGroup HTTP ${response.statusCode}: ${response.body}');
      throw Exception('Failed to fetch group: HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);

    // Support either a DRF paginated envelope or a bare list.
    final List<Group> groups;
    if (decoded is Map<String, dynamic> && decoded.containsKey('results')) {
      groups = PaginatedApiResponse<Group>.fromJson(
        decoded,
        Group.fromJson,
      ).results;
    } else if (decoded is List) {
      groups = decoded
          .map((e) => Group.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (decoded is Map<String, dynamic>) {
      // Single-object response.
      groups = [Group.fromJson(decoded)];
    } else {
      groups = const [];
    }

    if (groups.isEmpty) {
      _log.w('fetchGroup: no groups returned');
      return null;
    }

    final match = groups.where((g) => g.id == groupId).toList();
    final group = match.isNotEmpty ? match.first : groups.first;
    _log.i('fetchGroup: resolved group ${group.id} (${group.label})');
    return group;
  }
}
