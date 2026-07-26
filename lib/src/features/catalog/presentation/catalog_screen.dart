import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/barcode_scanner_listener.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../session/domain/cart_item.dart';
import '../../session/presentation/product_card.dart';
import '../data/catalog_pagination_controller.dart';
import '../data/catalog_sync_controller.dart';
import '../domain/catalog_item.dart';
import '../domain/catalog_state.dart';
import 'catalog_sync_modal.dart';

/// Browse screen for the synced catalog. Mirrors the app's catalog list:
/// cursor-paginated infinite scroll from the local ObjectBox store, reusing the
/// kiosk [ProductCard] for each item and the kiosk header design.
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  bool _keyboardWasOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(catalogPaginationControllerProvider.notifier).loadItems();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// When the OS keyboard is dismissed via its own hide button, the field stays
  /// focused (only the keyboard view goes away). Detect the keyboard closing
  /// (bottom inset → 0) and drop focus so the field fully deselects.
  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding
        .instance
        .platformDispatcher
        .views
        .first
        .viewInsets
        .bottom;
    final keyboardOpen = bottomInset > 0;
    if (_keyboardWasOpen && !keyboardOpen && _searchFocus.hasFocus) {
      _searchFocus.unfocus();
    }
    _keyboardWasOpen = keyboardOpen;
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref
          .read(catalogPaginationControllerProvider.notifier)
          .setSearch(_searchController.text);
    });
  }

  /// Fully deselect the search field and close the keyboard.
  ///
  /// Unfocusing the *node itself* (rather than only the enclosing
  /// [FocusScope]) is important: a scope-level unfocus leaves the field as the
  /// scope's "focused child", so when a route on top of us (e.g. the sync
  /// modal) is popped, Flutter's focus-restoration re-focuses the field and its
  /// `onTap` handler re-opens the keyboard. Unfocusing the node clears that
  /// restoration target so dismissal sticks.
  void _dismissKeyboard() {
    if (_searchFocus.hasFocus) {
      _searchFocus.unfocus();
    } else {
      // Nothing in our field is focused, but some other descendant might be —
      // fall back to the scope so an off-field tap still closes the keyboard.
      FocusScope.of(context).unfocus();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(catalogPaginationControllerProvider.notifier).setSearch('');
  }

  /// A USB barcode scanner reported a scan — route it into the search field and
  /// filter immediately (no debounce). Works even when the field isn't focused.
  void _onBarcodeScanned(String code) {
    _debounce?.cancel();
    _searchController
      ..text = code
      ..selection = TextSelection.collapsed(offset: code.length);
    ref.read(catalogPaginationControllerProvider.notifier).setSearch(code);
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final m = notification.metrics;
      if (m.pixels >= m.maxScrollExtent - 200) {
        final state = ref.read(catalogPaginationControllerProvider);
        if (state.hasMore && !state.isLoading) {
          ref
              .read(catalogPaginationControllerProvider.notifier)
              .loadItems(loadMore: true);
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final pagination = ref.watch(catalogPaginationControllerProvider);
    final isSyncing = ref.watch(
      catalogSyncControllerProvider.select((s) => s.isSyncing),
    );

    return Scaffold(
      // USB barcode scanner keystrokes are captured here and routed into the
      // search field, even when it isn't focused.
      body: BarcodeScannerListener(
        onScan: _onBarcodeScanned,
        child: SafeArea(
          // Tap anywhere off the search field to dismiss the keyboard + unfocus.
          // translucent so taps still reach buttons/list items underneath.
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _dismissKeyboard,
            child: Column(
              children: [
                _Header(count: pagination.totalCount),
                _SearchBar(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  onClear: _clearSearch,
                ),
                Expanded(
                  child: _Body(
                    pagination: pagination,
                    isSyncing: isSyncing,
                    scrollController: _scrollController,
                    onScroll: _onScroll,
                    onDismissKeyboard: _dismissKeyboard,
                    onRefresh: () => ref
                        .read(catalogPaginationControllerProvider.notifier)
                        .refresh(),
                    onRetry: () => ref
                        .read(catalogPaginationControllerProvider.notifier)
                        .loadItems(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kiosk-style header: back button, catalog icon + title + item-count pill on
/// the start edge, and a sync-status affordance on the end edge.
class _Header extends ConsumerWidget {
  const _Header({required this.count});

  final int count;

  static const double _appBarHeight = 96;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final titleStyle = Theme.of(context).textTheme.displayMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
      height: 1.0,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KioskTokens.spaceL,
        KioskTokens.spaceL,
        KioskTokens.spaceL,
        KioskTokens.spaceM,
      ),
      child: SizedBox(
        height: _appBarHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 40,
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: scheme.onSurfaceVariant,
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.home);
                      }
                    },
                  ),
                  const SizedBox(width: KioskTokens.spaceXS),
                  Icon(Icons.category_rounded, size: 56, color: scheme.primary),
                  const SizedBox(width: KioskTokens.spaceM),
                  Flexible(
                    child: Text(
                      l10n.catalogTitle,
                      style: titleStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: KioskTokens.spaceM),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: KioskTokens.spaceL,
                        vertical: KioskTokens.spaceS,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        l10n.itemsCount(count),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: KioskTokens.spaceM),
            const _SyncButton(),
          ],
        ),
      ),
    );
  }
}

/// Sync button with a colored status dot, in the catalog header. Tapping it
/// opens the info + sync modal. The dot color reflects the current sync state:
/// blue = syncing, orange = update available, red = error, green = up to date,
/// grey = never synced.
class _SyncButton extends ConsumerWidget {
  const _SyncButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(catalogSyncControllerProvider);

    final (Color color, bool spinning) = _status(scheme, state);

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Drop any search-field focus before the modal opens. Otherwise the
          // field remains the focus-restoration target and Flutter re-focuses
          // it (re-opening the keyboard) when the modal is dismissed.
          FocusManager.instance.primaryFocus?.unfocus();
          CatalogSyncModal.show(context, ref);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KioskTokens.spaceM,
            vertical: KioskTokens.spaceS,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The sync icon itself is the status indicator — its color
              // reflects the sync state and it rotates while syncing.
              _SyncIcon(color: color, spinning: spinning),
              const SizedBox(width: KioskTokens.spaceS),
              Text(
                l10n.catalogInfo,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Icon color + whether the icon should spin (rotate), from the sync state.
  (Color, bool) _status(ColorScheme scheme, CatalogState state) {
    if (state.isSyncing) return (scheme.primary, true);
    if (state.hasError) return (scheme.error, false);
    if (state.isUpdateAvailable) return (const Color(0xFFF59E0B), false);
    if (state.localSyncDate != null) return (const Color(0xFF4CAF50), false);
    return (scheme.onSurfaceVariant, false);
  }
}

/// The header sync icon: a colored [Icons.sync_rounded] that rotates
/// continuously while [spinning] (a sync is running).
class _SyncIcon extends StatefulWidget {
  const _SyncIcon({required this.color, required this.spinning});

  final Color color;
  final bool spinning;

  @override
  State<_SyncIcon> createState() => _SyncIconState();
}

class _SyncIconState extends State<_SyncIcon>
    with SingleTickerProviderStateMixin {
  // Constructed eagerly in initState (not via `late final`): a lazy initializer
  // that first fires inside dispose() would build the AnimationController — and
  // create its Ticker — against an already-deactivated element, throwing
  // "Looking up a deactivated widget's ancestor is unsafe." Eager construction
  // guarantees the controller always exists to be disposed.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.spinning) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _SyncIcon old) {
    super.didUpdateWidget(old);
    if (widget.spinning && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.spinning && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.sync_rounded, size: 28, color: widget.color);
    return widget.spinning
        ? RotationTransition(turns: _controller, child: icon)
        : icon;
  }
}

/// Search field filtering the catalog by product name or barcode. Debounced by
/// the parent; a clear button appears once there's text.
class _SearchBar extends ConsumerWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final hasText = ref.watch(
      catalogPaginationControllerProvider.select((s) => s.isSearching),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KioskTokens.spaceL,
        0,
        KioskTokens.spaceL,
        KioskTokens.spaceM,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.search,
        autocorrect: false,
        enableSuggestions: false,
        style: const TextStyle(fontSize: 26, height: 1.2),
        onTap: () => SystemChannels.textInput.invokeMethod('TextInput.show'),
        decoration: InputDecoration(
          hintText: l10n.catalogSearchHint,
          hintStyle: TextStyle(fontSize: 24, color: scheme.onSurfaceVariant),
          prefixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: KioskTokens.spaceM,
              end: KioskTokens.spaceS,
            ),
            child: Icon(
              Icons.search_rounded,
              size: 36,
              color: scheme.onSurfaceVariant,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 64,
            minHeight: 64,
          ),
          suffixIcon: hasText
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: KioskTokens.spaceS,
                    end: KioskTokens.spaceM,
                  ),
                  child: IconButton(
                    iconSize: 34,
                    icon: const Icon(Icons.close_rounded),
                    color: scheme.onSurfaceVariant,
                    onPressed: onClear,
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 64,
            minHeight: 64,
          ),
          filled: true,
          fillColor: scheme.surfaceContainerHigh,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 26,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(KioskTokens.radiusLarge),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.pagination,
    required this.isSyncing,
    required this.scrollController,
    required this.onScroll,
    required this.onDismissKeyboard,
    required this.onRefresh,
    required this.onRetry,
  });

  final CatalogPaginationData pagination;
  final bool isSyncing;
  final ScrollController scrollController;
  final bool Function(ScrollNotification) onScroll;
  final VoidCallback onDismissKeyboard;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (pagination.error != null && pagination.isEmpty) {
      return _ErrorState(message: pagination.error!, onRetry: onRetry);
    }
    if (pagination.isEmpty && pagination.isLoading) {
      return _CenteredMessage(
        icon: const _Spinner(),
        text: l10n.catalogLoading,
      );
    }
    if (pagination.isEmpty) {
      // Searching with no matches vs. a genuinely empty catalog.
      if (pagination.isSearching && !isSyncing) {
        return _CenteredMessage(
          icon: Icon(
            Icons.search_off_rounded,
            size: 96,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          text: l10n.catalogNoResults,
        );
      }
      return _CenteredMessage(
        icon: Icon(
          isSyncing ? Icons.sync_rounded : Icons.inventory_2_outlined,
          size: 96,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        text: isSyncing ? l10n.catalogSyncing : l10n.catalogEmpty,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: onScroll,
        child: ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(
            KioskTokens.spaceL,
            KioskTokens.spaceS,
            KioskTokens.spaceL,
            KioskTokens.spaceL,
          ),
          // +1 for the trailing load-more indicator when more pages remain.
          itemCount: pagination.items.length + (pagination.hasMore ? 1 : 0),
          separatorBuilder: (_, _) =>
              const SizedBox(height: KioskTokens.spaceS),
          itemBuilder: (context, index) {
            if (index >= pagination.items.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: KioskTokens.spaceL),
                child: Center(child: _Spinner()),
              );
            }
            final CatalogItem item = pagination.items[index];
            return ProductCard(
              key: ValueKey('catalog-${item.id}'),
              // Display-only wrapper so the cart-oriented card can render a
              // catalog row. No cart actions (browse mode) — tapping just
              // dismisses the search keyboard.
              item: CartItem(lineId: 'catalog-${item.id}', item: item),
              onTap: onDismissKeyboard,
            );
          },
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.icon, required this.text});

  final Widget icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: KioskTokens.spaceL),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KioskTokens.spaceL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 88, color: scheme.error),
            const SizedBox(height: KioskTokens.spaceL),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: KioskTokens.spaceL),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.catalogRetry),
            ),
          ],
        ),
      ),
    );
  }
}
