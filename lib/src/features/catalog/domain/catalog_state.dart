import 'catalog.dart';
import 'catalog_sync_models.dart';

/// The catalog sync state, owned by `CatalogSyncController`.
class CatalogState {
  final Catalog? catalogInfo;
  final DateTime? localSyncDate;
  final DateTime? serverLastUpdate;
  final bool isUpdateAvailable;
  final bool isCheckingForUpdates;
  final CatalogSyncData? syncProgress;
  final int? currentGroupId;
  final String? error;

  /// Total items in the local database.
  final int totalItems;

  const CatalogState({
    this.catalogInfo,
    this.localSyncDate,
    this.serverLastUpdate,
    this.isUpdateAvailable = false,
    this.isCheckingForUpdates = false,
    this.syncProgress,
    this.currentGroupId,
    this.error,
    this.totalItems = 0,
  });

  bool get needsSync =>
      currentGroupId != null && (isUpdateAvailable || catalogInfo == null);
  bool get isReady =>
      catalogInfo != null && localSyncDate != null && !needsSync;
  bool get isSyncing => syncProgress?.isActive ?? false;
  bool get hasError => error != null;

  CatalogState copyWith({
    Catalog? catalogInfo,
    DateTime? localSyncDate,
    DateTime? serverLastUpdate,
    bool? isUpdateAvailable,
    bool? isCheckingForUpdates,
    CatalogSyncData? syncProgress,
    int? currentGroupId,
    String? error,
    bool clearError = false,
    int? totalItems,
  }) {
    return CatalogState(
      catalogInfo: catalogInfo ?? this.catalogInfo,
      localSyncDate: localSyncDate ?? this.localSyncDate,
      serverLastUpdate: serverLastUpdate ?? this.serverLastUpdate,
      isUpdateAvailable: isUpdateAvailable ?? this.isUpdateAvailable,
      isCheckingForUpdates: isCheckingForUpdates ?? this.isCheckingForUpdates,
      syncProgress: syncProgress ?? this.syncProgress,
      currentGroupId: currentGroupId ?? this.currentGroupId,
      error: clearError ? null : (error ?? this.error),
      totalItems: totalItems ?? this.totalItems,
    );
  }

  factory CatalogState.initial({int? currentGroupId}) {
    return CatalogState(
      currentGroupId: currentGroupId,
      syncProgress: CatalogSyncData.inactive,
    );
  }

  factory CatalogState.afterDeletion({int? currentGroupId}) {
    return CatalogState(
      currentGroupId: currentGroupId,
      syncProgress: CatalogSyncData.inactive,
    );
  }

  CatalogState clearError() => copyWith(clearError: true);

  @override
  String toString() =>
      'CatalogState{isReady: $isReady, needsSync: $needsSync, '
      'groupId: $currentGroupId, isSyncing: $isSyncing, totalItems: $totalItems}';
}
