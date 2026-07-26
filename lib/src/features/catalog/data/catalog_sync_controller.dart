import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../auth/data/auth_controller.dart';
import '../../group/data/group_controller.dart';
import '../domain/catalog.dart';
import '../domain/catalog_state.dart';
import '../domain/catalog_sync_models.dart';
import 'catalog_service.dart';

final _log = AppLogger.instance;

/// Owns the catalog sync lifecycle for the kiosk. Consolidates what the field
/// app splits across CatalogManager + CatalogSyncCoordinator + CatalogSyncController
/// (the app's split existed for FCM events / count-refresh / UI projection —
/// none of which the kiosk needs).
///
/// Responsibilities:
///  - (re)initialize when the group changes (login / restore),
///  - fetch catalog metadata and decide whether a sync is needed,
///  - run the download + import (with an etag "file unchanged" gate),
///  - persist sync metadata so restarts skip a redundant re-download.
class CatalogSyncController extends Notifier<CatalogState> {
  CatalogService get _service => ref.read(catalogServiceProvider);

  @override
  CatalogState build() {
    // React to group selection (set after login / restored from storage).
    ref.listen(groupControllerProvider, (prev, next) {
      final newId = next.groupId;
      final currentId = state.currentGroupId;
      if (newId == null) {
        if (currentId != null) {
          _log.i('Group deselected — resetting catalog state');
          state = CatalogState.initial();
        }
        return;
      }
      if (newId != currentId) {
        _log.i('Group selected ($newId) — initializing catalog');
        state = CatalogState.initial(currentGroupId: newId);
        unawaited(initializeCatalog());
      }
    });

    return CatalogState.initial();
  }

  int? get _groupId => ref.read(groupControllerProvider).groupId;
  String? get _slug => ref.read(authControllerProvider).user?.tenantSlug;

  /// Fetch metadata, load the DB count, check for updates, and auto-sync when
  /// needed. Called after login / group selection.
  Future<void> initializeCatalog() async {
    final groupId = _groupId;
    if (groupId == null) {
      _log.d('initializeCatalog: no group selected, skipping');
      return;
    }

    try {
      final localCount = _service.itemCount();
      final catalogInfo =
          await _service.getCatalog(groupId: groupId, tenantSlug: _slug);
      final localSyncDate = await _service.getLastSyncDate();

      state = CatalogState(
        catalogInfo: catalogInfo,
        localSyncDate: localSyncDate,
        serverLastUpdate: catalogInfo.updatedAt,
        currentGroupId: groupId,
        totalItems: localCount > 0 ? localCount : catalogInfo.totalItems,
        syncProgress: CatalogSyncData.inactive,
      );

      // Only fetch metadata + compute whether an update is available; the
      // actual download/import is user-initiated (the "Sync Now" button in the
      // catalog sync modal). We intentionally do NOT auto-start a sync here.
      await checkForUpdates(silent: true);
    } catch (e, st) {
      _log.e('Failed to initialize catalog', error: e, stackTrace: st);
      state = state.copyWith(error: 'Failed to initialize catalog: $e');
    }
  }

  /// Re-fetch metadata and recompute whether an update is available.
  Future<void> checkForUpdates({bool silent = false}) async {
    final groupId = _groupId;
    if (groupId == null) return;

    if (!silent) {
      state = state.copyWith(isCheckingForUpdates: true);
    }
    try {
      final catalogInfo =
          await _service.getCatalog(groupId: groupId, tenantSlug: _slug);
      final localSyncDate = await _service.getLastSyncDate();
      final localUpdatedAt = await _service.getCatalogUpdatedAt();

      final needsUpdate = _service.needsSyncWithValues(
        catalogInfo.updatedAt,
        localSyncDate,
        localUpdatedAt,
      );

      state = state.copyWith(
        catalogInfo: catalogInfo,
        serverLastUpdate: catalogInfo.updatedAt,
        localSyncDate: localSyncDate,
        isUpdateAvailable: needsUpdate,
        isCheckingForUpdates: false,
      );
      _log.i('Update check: needsUpdate=$needsUpdate');
    } catch (e, st) {
      _log.e('Failed to check for updates', error: e, stackTrace: st);
      state = state.copyWith(
        isCheckingForUpdates: false,
        error: 'Failed to check for updates: $e',
      );
    }
  }

  /// Run the sync: fresh metadata → etag gate → download + import → persist.
  Future<void> syncCatalog() async {
    if (state.isSyncing) {
      _log.w('Sync already in progress, skipping');
      return;
    }
    final groupId = _groupId;
    if (groupId == null) {
      _log.e('Cannot sync catalog: no group selected');
      return;
    }

    state = state.copyWith(
      syncProgress: const CatalogSyncData(
        status: CatalogSyncStatus.checkingVersion,
        statusMessage: 'Starting sync...',
      ),
      clearError: true,
    );

    try {
      // Always refetch fresh metadata so post-sync data reflects the new file.
      Catalog catalogInfo;
      try {
        catalogInfo =
            await _service.getCatalog(groupId: groupId, tenantSlug: _slug);
        state = state.copyWith(
          catalogInfo: catalogInfo,
          serverLastUpdate: catalogInfo.updatedAt,
        );
      } catch (e) {
        final cached = state.catalogInfo;
        if (cached == null) rethrow;
        _log.w('Failed to refresh metadata before sync, using cached: $e');
        catalogInfo = cached;
      }

      if (!catalogInfo.hasItems) {
        _log.i('No catalog available for group $groupId');
        state = state.copyWith(
          syncProgress: CatalogSyncData.inactive,
          isUpdateAvailable: false,
        );
        return;
      }

      // Etag gate: skip the download when the file hasn't changed.
      final serverNorm = _normalizeEtag(catalogInfo.fileInfo?.etag);
      final storedNorm =
          _normalizeEtag((await _service.getStoredFileInfo())?.etag);
      if (serverNorm != null && serverNorm == storedNorm) {
        _log.i('Catalog file unchanged (etag match) — skipping download');
        await _service.savePostSyncMetadata(
          catalogInfo.updatedAt,
          catalogInfo.fileInfo,
        );
        state = state.copyWith(
          syncProgress: const CatalogSyncData(
            status: CatalogSyncStatus.completed,
            progress: 1.0,
            statusMessage: 'Catalog is up to date',
          ),
          localSyncDate: catalogInfo.updatedAt,
          isUpdateAvailable: false,
          totalItems: catalogInfo.totalItems,
          clearError: true,
        );
        return;
      }

      final downloadInfo = await _service.getCatalogDownloadUrl(
        groupId: groupId,
        tenantSlug: _slug,
      );
      if (downloadInfo == null) {
        throw Exception('Catalog file is not ready on the server');
      }

      final result = await _service.updateCatalogFromJsonlGz(
        downloadInfo: downloadInfo,
        expectedItemCount: catalogInfo.totalItems,
        onStatusChange: (status, {String? message, double? progress}) {
          if (status == CatalogSyncStatus.completed ||
              status == CatalogSyncStatus.error) {
            return; // final transitions handled atomically below
          }
          state = state.copyWith(
            syncProgress: CatalogSyncData(
              status: status,
              progress: progress ?? state.syncProgress?.progress ?? 0.0,
              statusMessage: message,
            ),
          );
        },
      );

      if (result.success) {
        await _service.savePostSyncMetadata(
          catalogInfo.updatedAt,
          catalogInfo.fileInfo,
          downloadEtag: downloadInfo.etag,
        );
        state = state.copyWith(
          syncProgress: CatalogSyncData(
            status: CatalogSyncStatus.completed,
            progress: 1.0,
            statusMessage: result.message,
            result: result,
          ),
          localSyncDate: catalogInfo.updatedAt,
          isUpdateAvailable: false,
          totalItems: catalogInfo.totalItems,
          clearError: true,
        );
        _log.i('Catalog sync completed: ${result.itemsProcessed} items');
      } else {
        state = state.copyWith(
          syncProgress: CatalogSyncData(
            status: CatalogSyncStatus.error,
            statusMessage: 'Sync failed: ${result.error}',
            error: result.error,
            result: result,
          ),
          error: result.error,
        );
        _log.e('Catalog sync failed: ${result.error}');
      }
    } catch (e, st) {
      _log.e('Catalog sync error', error: e, stackTrace: st);
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        syncProgress: CatalogSyncData(
          status: CatalogSyncStatus.error,
          statusMessage: 'Sync failed: $msg',
          error: msg,
        ),
        error: msg,
      );
    }
  }

  /// Reset only the live sync progress back to inactive, clearing any leftover
  /// completed/error result so the sync modal shows a fresh "ready" state next
  /// time it opens. No-op while a sync is running (don't interrupt live
  /// progress). Leaves catalog metadata, update-available and sync-date intact.
  void resetSyncProgress() {
    if (state.isSyncing) return;
    state = state.copyWith(
      syncProgress: CatalogSyncData.inactive,
      clearError: true,
    );
  }

  /// Reset catalog state (on logout).
  Future<void> reset() async {
    await _service.clearAllSyncMetadata();
    await _service.deleteCatalog();
    state = CatalogState.initial();
  }

  /// Normalize an etag for comparison: strip a weak-validator `W/` prefix,
  /// surrounding quotes, and whitespace, then lower-case. Null for blank input.
  String? _normalizeEtag(String? etag) {
    if (etag == null) return null;
    var e = etag.trim();
    if (e.startsWith('W/')) e = e.substring(2).trim();
    if (e.length >= 2 && e.startsWith('"') && e.endsWith('"')) {
      e = e.substring(1, e.length - 1);
    }
    e = e.trim().toLowerCase();
    return e.isEmpty ? null : e;
  }
}

final catalogSyncControllerProvider =
    NotifierProvider<CatalogSyncController, CatalogState>(
  CatalogSyncController.new,
);

/// Convenience: current sync progress as a 0..1 fraction.
final catalogSyncProgressProvider = Provider<double>((ref) {
  return ref.watch(catalogSyncControllerProvider).syncProgress?.progress ?? 0.0;
});
