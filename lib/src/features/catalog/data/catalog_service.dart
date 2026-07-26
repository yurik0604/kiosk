import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../objectbox.g.dart';
import '../../../core/config/app_config.dart';
import '../../../core/database/object_box.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/authed_api_client.dart';
import '../../auth/data/secure_storage.dart';
import '../domain/catalog.dart';
import '../domain/catalog_download_info.dart';
import '../domain/catalog_item.dart';
import '../domain/catalog_sync_models.dart';
import 'catalog_item_mapper.dart';
import 'jsonl_catalog_import_service.dart';
import 'catalog_repository.dart';

final _log = AppLogger.instance;

final catalogServiceProvider = Provider<CatalogService>((ref) {
  return CatalogService(
    ref.watch(objectBoxProvider),
    ref.read(authedApiClientProvider),
  );
});

/// A page of catalog items plus the cursor for the next page.
class CatalogPaginationResult {
  const CatalogPaginationResult({
    required this.items,
    required this.hasMore,
    required this.nextCursor,
    required this.totalCount,
  });

  final List<CatalogItem> items;
  final bool hasMore;
  final int? nextCursor;
  final int totalCount;
}

/// Catalog data access + API + sync-metadata persistence.
///
/// Metadata is stored under single (non-per-group) secure-storage keys — only
/// the current group's metadata exists at a time. On group change it's cleared,
/// and on successful sync it's saved again.
class CatalogService {
  CatalogService(this._objectBox, this._api);

  final ObjectBox _objectBox;
  final AuthedApiClient _api;
  final SecureStorage _storage = SecureStorage();

  Store get _store => _objectBox.store;
  Box<CatalogItem> get _box => _objectBox.catalogItems;

  static const _syncDateKey = 'kiosk_catalog_sync_date';
  static const _catalogUpdatedAtKey = 'kiosk_catalog_updated_at';
  static const _catalogFileInfoKey = 'kiosk_catalog_file_info';
  static const _downloadEtagKey = 'kiosk_catalog_download_etag';

  // ── API ─────────────────────────────────────────────────────

  /// Fetch catalog metadata from `GET v1/groups/{id}/catalog/`.
  Future<Catalog> getCatalog({
    required int groupId,
    required String? tenantSlug,
  }) async {
    final response = await _api.get(
      AppConfig.catalogEndpoint(groupId),
      tenantSlug: tenantSlug,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch catalog: HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    final Map<String, dynamic> jsonData = decoded is List && decoded.isNotEmpty
        ? decoded.first as Map<String, dynamic>
        : decoded as Map<String, dynamic>;

    final catalog = Catalog.fromJson(jsonData);
    _log.d('getCatalog: id=${catalog.id} totalItems=${catalog.totalItems} '
        'updatedAt=${catalog.updatedAt}');
    return catalog;
  }

  /// Get the presigned download info, or null if the file isn't ready yet.
  Future<CatalogDownloadInfo?> getCatalogDownloadUrl({
    required int groupId,
    required String? tenantSlug,
  }) async {
    final response = await _api.get(
      AppConfig.catalogDownloadUrlEndpoint(groupId),
      tenantSlug: tenantSlug,
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to get catalog download URL: HTTP ${response.statusCode}');
    }

    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      jsonData,
      (data) => data as Map<String, dynamic>,
    );

    if (apiResponse.data == null) {
      _log.w('getCatalogDownloadUrl: catalog file not ready');
      return null;
    }
    return CatalogDownloadInfo.fromJson(apiResponse.data!);
  }

  /// Download the JSONL.GZ from S3 and import into ObjectBox.
  ///
  /// Progress: 0–40% download, 40–45% clear, 45–100% import.
  Future<CatalogSyncResult> updateCatalogFromJsonlGz({
    required CatalogDownloadInfo downloadInfo,
    int? expectedItemCount,
    void Function(CatalogSyncStatus status, {String? message, double? progress})?
        onStatusChange,
  }) async {
    final stopwatch = Stopwatch()..start();
    String? downloadedFilePath;

    try {
      // Phase 1: download (0–40%).
      onStatusChange?.call(
        CatalogSyncStatus.fetchingCatalogItems,
        message: 'Downloading catalog...',
        progress: 0.0,
      );

      downloadedFilePath = await _api.downloadFileToTempStreaming(
        downloadInfo.downloadUrl,
        fileName: 'catalog.jsonl.gz',
        expectedFileSize: downloadInfo.fileSize,
        onProgress: (received, total) {
          final p = total > 0 ? received / total : 0.0;
          onStatusChange?.call(
            CatalogSyncStatus.fetchingCatalogItems,
            message: 'Downloading catalog... ${(p * 100).toStringAsFixed(0)}%',
            progress: p * 0.4,
          );
        },
      );

      final downloadedFile = File(downloadedFilePath);
      final actualSize = downloadedFile.lengthSync();
      if (actualSize == 0) {
        throw Exception('Downloaded file is empty');
      }
      if (downloadInfo.fileSize > 0 && actualSize != downloadInfo.fileSize) {
        throw Exception('Download incomplete: expected '
            '${downloadInfo.fileSize} bytes, got $actualSize bytes');
      }

      // Phase 2: clear existing catalog (40–45%).
      onStatusChange?.call(
        CatalogSyncStatus.importingData,
        message: 'Clearing existing catalog...',
        progress: 0.4,
      );
      await _store.runInTransactionAsync(
        TxMode.write,
        clearDatabaseCallback,
        null,
      );

      // Phase 3: stream-parse + batch-insert (45–100%).
      onStatusChange?.call(
        CatalogSyncStatus.importingData,
        message: 'Importing catalog items...',
        progress: 0.45,
      );

      final importedCount = await JsonlCatalogImportService().importJsonlGz(
        filePath: downloadedFilePath,
        store: _store,
        itemCount: expectedItemCount,
        onProgress: (processed, total) {
          final p = total > 0 ? processed / total : 0.0;
          onStatusChange?.call(
            CatalogSyncStatus.importingData,
            message: 'Importing items... $processed'
                '${total > 0 ? '/$total' : ''}',
            progress: 0.45 + (p * 0.55),
          );
        },
      );

      stopwatch.stop();
      onStatusChange?.call(
        CatalogSyncStatus.completed,
        message: 'Import complete',
        progress: 1.0,
      );

      return CatalogSyncResult.success(
        message: 'Catalog imported successfully',
        itemsProcessed: importedCount,
        duration: stopwatch.elapsed,
      );
    } catch (e, st) {
      stopwatch.stop();
      _log.e('JSONL import failed', error: e, stackTrace: st);
      onStatusChange?.call(
        CatalogSyncStatus.error,
        message: 'Import failed: $e',
      );
      return CatalogSyncResult.error('Import failed: $e');
    } finally {
      if (downloadedFilePath != null) {
        try {
          File(downloadedFilePath).deleteSync();
        } catch (_) {}
      }
    }
  }

  // ── Local reads ─────────────────────────────────────────────

  int itemCount() => _box.count();

  /// Page of catalog items using keyset (cursor) pagination on `id`, optionally
  /// filtered by a [search] term matched (case-insensitive, substring) against
  /// the item `name` or `barcode`.
  ///
  /// [cursor] is the `id` of the last item from the previous page (null for the
  /// first page). Fetches `pageSize + 1` rows to detect whether more remain;
  /// `nextCursor` is the last returned item's `id`.
  CatalogPaginationResult getItems({
    int? cursor,
    int pageSize = 50,
    String? search,
  }) {
    final term = search?.trim() ?? '';

    Condition<CatalogItem>? condition;
    if (cursor != null) {
      condition = CatalogItem_.id.greaterThan(cursor);
    }
    if (term.isNotEmpty) {
      final byName = CatalogItem_.name.contains(term, caseSensitive: false);
      final byBarcode =
          CatalogItem_.barcode.contains(term, caseSensitive: false);
      final searchCond = byName | byBarcode;
      condition = condition == null ? searchCond : condition & searchCond;
    }

    final builder =
        condition != null ? _box.query(condition) : _box.query();
    final query = (builder..order(CatalogItem_.id)).build();
    try {
      query.limit = pageSize + 1;
      var items = query.find();
      final hasMore = items.length > pageSize;
      if (hasMore) items = items.take(pageSize).toList();

      // totalCount reflects the active filter (full box count when unfiltered).
      final int totalCount;
      if (term.isEmpty) {
        totalCount = _box.count();
      } else {
        final countQuery = _box
            .query(CatalogItem_.name.contains(term, caseSensitive: false) |
                CatalogItem_.barcode.contains(term, caseSensitive: false))
            .build();
        try {
          totalCount = countQuery.count();
        } finally {
          countQuery.close();
        }
      }

      return CatalogPaginationResult(
        items: items,
        hasMore: hasMore,
        nextCursor: hasMore && items.isNotEmpty ? items.last.id : null,
        totalCount: totalCount,
      );
    } finally {
      query.close();
    }
  }

  Future<void> deleteCatalog() async {
    await _store.runInTransactionAsync(TxMode.write, clearDatabaseCallback, null);
  }

  // ── Sync metadata ───────────────────────────────────────────

  Future<DateTime?> getLastSyncDate() async {
    final s = await _storage.read(_syncDateKey);
    return s == null ? null : DateTime.tryParse(s);
  }

  Future<void> setLastSyncDate(DateTime date) =>
      _storage.write(_syncDateKey, date.toIso8601String());

  Future<DateTime?> getCatalogUpdatedAt() async {
    final s = await _storage.read(_catalogUpdatedAtKey);
    return s == null ? null : DateTime.tryParse(s);
  }

  /// Whether a sync is needed, comparing the server `updatedAt` against the
  /// locally stored values.
  bool needsSyncWithValues(
    DateTime serverUpdatedAt,
    DateTime? localSyncDate,
    DateTime? localUpdatedAt,
  ) {
    if (localSyncDate == null || localUpdatedAt == null) {
      _log.d('Catalog needs sync: no local metadata');
      return true;
    }
    if (serverUpdatedAt.isAfter(localUpdatedAt)) {
      _log.d('Catalog needs sync: server $serverUpdatedAt > local $localUpdatedAt');
      return true;
    }
    return false;
  }

  Future<void> savePostSyncMetadata(
    DateTime updatedAt,
    CatalogFileInfo? fileInfo, {
    String? downloadEtag,
  }) async {
    await setLastSyncDate(updatedAt);
    await _storage.write(_catalogUpdatedAtKey, updatedAt.toIso8601String());
    if (fileInfo != null) {
      await _storage.write(_catalogFileInfoKey, jsonEncode(fileInfo.toJson()));
    }
    if (downloadEtag != null) {
      await _storage.write(_downloadEtagKey, downloadEtag);
    }
  }

  Future<void> clearAllSyncMetadata() async {
    await _storage.delete(_syncDateKey);
    await _storage.delete(_catalogUpdatedAtKey);
    await _storage.delete(_catalogFileInfoKey);
    await _storage.delete(_downloadEtagKey);
  }

  Future<String?> getStoredDownloadEtag() => _storage.read(_downloadEtagKey);

  Future<void> saveDownloadEtag(String etag) =>
      _storage.write(_downloadEtagKey, etag);

  /// The file info saved after the last successful import (its `etag` is the
  /// stable per-version validator used to skip re-downloading an unchanged
  /// catalog).
  Future<CatalogFileInfo?> getStoredFileInfo() async {
    try {
      final s = await _storage.read(_catalogFileInfoKey);
      if (s == null || s.isEmpty) return null;
      return CatalogFileInfo.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (e) {
      _log.w('Failed to read stored catalog fileInfo: $e');
      return null;
    }
  }
}
