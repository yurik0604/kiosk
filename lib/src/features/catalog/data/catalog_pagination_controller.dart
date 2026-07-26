import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/catalog_item.dart';
import 'catalog_service.dart';
import 'catalog_sync_controller.dart';

final _log = AppLogger.instance;

/// Immutable state for the catalog browse list.
class CatalogPaginationData {
  const CatalogPaginationData({
    this.items = const [],
    this.hasMore = true,
    this.nextCursor,
    this.totalCount = 0,
    this.isLoading = false,
    this.error,
    this.search = '',
  });

  final List<CatalogItem> items;
  final bool hasMore;
  final int? nextCursor;
  final int totalCount;
  final bool isLoading;
  final String? error;

  /// The active search term (empty when not searching).
  final String search;

  bool get isEmpty => items.isEmpty;
  bool get isSearching => search.isNotEmpty;

  CatalogPaginationData copyWith({
    List<CatalogItem>? items,
    bool? hasMore,
    int? nextCursor,
    int? totalCount,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? search,
  }) {
    return CatalogPaginationData(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: nextCursor ?? this.nextCursor,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      search: search ?? this.search,
    );
  }
}

/// Drives the paginated catalog list read from the local ObjectBox store.
///
/// Mirrors the app's `CatalogPaginationState`: cursor-based paging via
/// [CatalogService.getItems], and an automatic page-1 reload when a catalog
/// sync completes (so freshly imported items appear).
class CatalogPaginationController extends Notifier<CatalogPaginationData> {
  static const int _pageSize = 50;

  CatalogService get _service => ref.read(catalogServiceProvider);

  @override
  CatalogPaginationData build() {
    // Reload the first page when a sync finishes (syncing → not-syncing, no
    // error) so newly imported items show without a manual refresh.
    ref.listen(catalogSyncControllerProvider, (prev, next) {
      final wasSyncing = prev?.isSyncing ?? false;
      if (wasSyncing && !next.isSyncing && !next.hasError) {
        _log.i('Catalog sync completed — reloading catalog list');
        loadItems();
      }
    });
    return const CatalogPaginationData();
  }

  /// Load a page. [loadMore] appends the next page; otherwise resets to page 1.
  /// Filters by the current [CatalogPaginationData.search] term.
  Future<void> loadItems({bool loadMore = false}) async {
    if (state.isLoading) return;
    if (loadMore && !state.hasMore) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cursor = loadMore ? state.nextCursor : null;
      final result = _service.getItems(
        cursor: cursor,
        pageSize: _pageSize,
        search: state.search,
      );
      state = state.copyWith(
        items: loadMore ? [...state.items, ...result.items] : result.items,
        hasMore: result.hasMore,
        nextCursor: result.nextCursor,
        totalCount: result.totalCount,
        isLoading: false,
      );
    } catch (e, st) {
      _log.e('Failed to load catalog items', error: e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Set the search term and reload from page 1. A no-op when the (trimmed)
  /// term is unchanged.
  Future<void> setSearch(String term) async {
    final normalized = term.trim();
    if (normalized == state.search) return;
    // Reset paging fields for a fresh page-1 query under the new term.
    state = state.copyWith(
      search: normalized,
      items: const [],
      nextCursor: null,
      hasMore: true,
      isLoading: false,
    );
    await loadItems();
  }

  Future<void> refresh() => loadItems();
}

final catalogPaginationControllerProvider =
    NotifierProvider<CatalogPaginationController, CatalogPaginationData>(
  CatalogPaginationController.new,
);
