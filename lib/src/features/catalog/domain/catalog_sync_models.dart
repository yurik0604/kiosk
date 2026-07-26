/// Phases of a catalog sync, in order.
enum CatalogSyncStatus {
  inactive('INACTIVE'),
  checkingVersion('CHECKING_VERSION'),
  fetchingCatalogItems('FETCHING_CATALOG_ITEMS'),
  importingData('IMPORTING_DATA'),
  completed('COMPLETED'),
  error('ERROR');

  const CatalogSyncStatus(this.value);
  final String value;

  @override
  String toString() => value;
}

/// Final outcome of a sync attempt.
class CatalogSyncResult {
  final bool success;
  final String? message;
  final bool wasAlreadyUpToDate;
  final int? itemsProcessed;
  final Duration? duration;
  final String? error;

  /// The download etag persisted after a successful import, compared on the
  /// next sync to skip re-importing an unchanged file.
  final String? downloadEtag;

  const CatalogSyncResult({
    required this.success,
    this.message,
    this.wasAlreadyUpToDate = false,
    this.itemsProcessed,
    this.duration,
    this.error,
    this.downloadEtag,
  });

  CatalogSyncResult.success({
    String? message,
    bool wasAlreadyUpToDate = false,
    int? itemsProcessed,
    Duration? duration,
    String? downloadEtag,
  }) : this(
          success: true,
          message: message,
          wasAlreadyUpToDate: wasAlreadyUpToDate,
          itemsProcessed: itemsProcessed,
          duration: duration,
          downloadEtag: downloadEtag,
        );

  CatalogSyncResult.error(String error)
      : this(
          success: false,
          error: error,
        );

  @override
  String toString() {
    if (success) {
      if (wasAlreadyUpToDate) return 'Catalog is already up to date';
      return 'Sync completed. ${itemsProcessed ?? 0} items in '
          '${duration?.inMilliseconds ?? 0}ms';
    }
    return 'Sync failed: $error';
  }
}

/// Live progress snapshot while a sync is running.
class CatalogSyncData {
  final CatalogSyncStatus status;
  final double progress;
  final String? statusMessage;
  final CatalogSyncResult? result;
  final String? error;

  const CatalogSyncData({
    required this.status,
    this.progress = 0.0,
    this.statusMessage,
    this.result,
    this.error,
  });

  bool get isActive =>
      status != CatalogSyncStatus.inactive &&
      status != CatalogSyncStatus.completed &&
      status != CatalogSyncStatus.error;
  bool get isCompleted => status == CatalogSyncStatus.completed;
  bool get hasError => status == CatalogSyncStatus.error;

  CatalogSyncData copyWith({
    CatalogSyncStatus? status,
    double? progress,
    String? statusMessage,
    CatalogSyncResult? result,
    String? error,
  }) {
    return CatalogSyncData(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }

  static const CatalogSyncData inactive = CatalogSyncData(
    status: CatalogSyncStatus.inactive,
  );

  @override
  String toString() =>
      'CatalogSyncData{status: $status, progress: $progress, message: $statusMessage}';
}
