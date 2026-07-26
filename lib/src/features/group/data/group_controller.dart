import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/logging/app_logger.dart';
import '../../auth/data/auth_controller.dart';
import '../../auth/data/secure_storage.dart';
import '../../catalog/data/catalog_sync_controller.dart';
import '../domain/group.dart';
import '../domain/group_state.dart';
import 'group_service.dart';

final _log = AppLogger.instance;

/// Owns the kiosk's group state (root fields + `group_settings`).
///
/// Initialized after a successful login / session-restore. Persists the group
/// to secure storage so it's available offline and instantly on the next boot.
class GroupController extends Notifier<GroupStateData> {
  final SecureStorage _storage = SecureStorage();

  @override
  GroupStateData build() => const GroupStateData.unknown();

  GroupService get _service => ref.read(groupServiceProvider);

  /// Resolve the device's group id from the logged-in user's
  /// `customer_group_ids` (first one). The kiosk device is scoped to a single
  /// group via its user.
  int? _resolveGroupId() {
    final user = ref.read(authControllerProvider).user;
    final ids = user?.customerGroupIds ?? const [];
    return ids.isNotEmpty ? ids.first : null;
  }

  /// Fetch and initialize the group after login / session-restore.
  ///
  /// Detects when the logged-in user belongs to a DIFFERENT group or tenant than
  /// the one cached locally from a previous session. In that case everything is
  /// wiped and re-initialized from scratch: the local catalog (items + sync
  /// metadata + state) is reset, the saved group is deleted, and the group is
  /// re-fetched fresh. When the group matches, the cache is restored for instant
  /// readiness, then refreshed from the API. No-ops (stays `unknown`) when no
  /// group id can be resolved.
  Future<void> initialize() async {
    final groupId = _resolveGroupId();
    if (groupId == null) {
      _log.w('GroupController: no group id available; staying unknown');
      return;
    }

    final user = ref.read(authControllerProvider).user;
    final slug = user?.tenantSlug;
    final tenantId = user?.tenantId;

    // Compare the logged-in user's group/tenant against the locally cached
    // group. A mismatch means a different user/group/tenant → hard reset.
    final cached = await _readCachedGroup();
    final isDifferent = cached != null &&
        (cached.id != groupId ||
            (tenantId != null && cached.tenantId != tenantId));

    if (isDifferent) {
      _log.i('GroupController: logged-in group/tenant differs from cache '
          '(cached group=${cached.id}/tenant=${cached.tenantId}, '
          'new group=$groupId/tenant=$tenantId) — wiping local data');
      await _wipeForNewGroup();
    } else if (cached != null) {
      // Same group — restore immediately so downstream (catalog) can start
      // against a known group even if the network is momentarily unavailable.
      state = GroupStateData.ready(cached);
    }

    if (state.status != GroupStatus.ready) {
      state = const GroupStateData.loading();
    }

    try {
      final group =
          await _service.fetchGroup(groupId: groupId, tenantSlug: slug);
      if (group == null) {
        if (state.status != GroupStatus.ready) {
          state = const GroupStateData.error('No group available');
        }
        return;
      }
      state = GroupStateData.ready(group);
      await _persist(group);
      _log.i('GroupController: group ${group.id} initialized');
    } catch (e, st) {
      _log.e('GroupController: fetch failed', error: e, stackTrace: st);
      // Keep any restored group; only surface an error if we have nothing.
      if (state.status != GroupStatus.ready) {
        state = GroupStateData.error(e.toString());
      }
    }
  }

  /// Wipe all catalog + group data for a group/tenant switch, then start fresh.
  Future<void> _wipeForNewGroup() async {
    // Catalog: delete local items, clear sync metadata, reset catalog state.
    try {
      await ref.read(catalogSyncControllerProvider.notifier).reset();
    } catch (e) {
      _log.w('GroupController: failed to reset catalog on group switch: $e');
    }
    // Group: delete the saved group and start from scratch.
    await _storage.delete(AppConfig.groupStorageKey);
    state = const GroupStateData.unknown();
  }

  /// Peek the cached group from storage WITHOUT committing it to state. Returns
  /// null when there's no cache or it can't be parsed (clearing bad data).
  Future<Group?> _readCachedGroup() async {
    try {
      final raw = await _storage.read(AppConfig.groupStorageKey);
      if (raw == null || raw.isEmpty) return null;
      return Group.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      _log.w('GroupController: failed to read cached group: $e');
      await _storage.delete(AppConfig.groupStorageKey);
      return null;
    }
  }

  Future<void> _persist(Group group) async {
    try {
      await _storage.write(
        AppConfig.groupStorageKey,
        jsonEncode(group.toJson()),
      );
    } catch (e) {
      _log.w('GroupController: failed to persist group: $e');
    }
  }

  /// Clear group state and storage (on logout).
  Future<void> clear() async {
    await _storage.delete(AppConfig.groupStorageKey);
    state = const GroupStateData.unknown();
  }
}

final groupControllerProvider =
    NotifierProvider<GroupController, GroupStateData>(GroupController.new);
