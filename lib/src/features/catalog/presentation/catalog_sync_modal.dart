import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/catalog_sync_controller.dart';
import '../domain/catalog_state.dart';
import '../domain/catalog_sync_models.dart';

/// Bottom-sheet showing catalog info + sync progress with a "Sync Now" action.
/// Kiosk counterpart of the app's `CatalogSyncModal`.
abstract final class CatalogSyncModal {
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => const _CatalogSyncModalContent(),
    );
    // Once dismissed, clear any leftover completed/error progress so the modal
    // opens fresh next time. No-op if a sync is still running.
    ref.read(catalogSyncControllerProvider.notifier).resetSyncProgress();
  }
}

class _CatalogSyncModalContent extends ConsumerWidget {
  const _CatalogSyncModalContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(catalogSyncControllerProvider);

    final hasCatalog = state.catalogInfo != null;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(KioskTokens.radiusLarge),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            KioskTokens.spaceL,
            KioskTokens.spaceM,
            KioskTokens.spaceL,
            KioskTokens.spaceL,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 6,
                  margin: const EdgeInsets.only(bottom: KioskTokens.spaceM),
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.sync_rounded, size: 32, color: scheme.primary),
                  const SizedBox(width: KioskTokens.spaceS),
                  Expanded(
                    child: Text(
                      l10n.catalogSyncTitle,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.close_rounded),
                    color: scheme.onSurfaceVariant,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: KioskTokens.spaceM),

              _InfoCard(state: state),
              const SizedBox(height: KioskTokens.spaceM),

              _SyncProgressSection(state: state),
              const SizedBox(height: KioskTokens.spaceL),

              if (!hasCatalog)
                _NoCatalogNote()
              else
                _SyncButton(state: state),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Info card ───────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.state});
  final CatalogState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final rows = _rows(context, l10n, scheme, locale);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KioskTokens.radiusMedium),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            _InfoRow(row: rows[i]),
          ],
        ],
      ),
    );
  }

  List<_Row> _rows(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme scheme,
    String locale,
  ) {
    String fmtDate(DateTime? d) => d != null
        ? DateFormat('dd MMM yyyy, HH:mm', locale).format(d.toLocal())
        : l10n.catalogNever;

    // Status row (colored).
    final (String statusText, Color statusColor) = _status(l10n, scheme);

    final totalItems = state.catalogInfo?.totalItems ?? state.totalItems;

    final validityText = () {
      final days = state.catalogInfo?.validityDays;
      if (days == null) return '—';
      if (days == 0) return l10n.catalogValidityNeverExpires;
      return l10n.catalogValidityDays(days);
    }();

    return [
      _Row(l10n.catalogStatus, statusText, valueColor: statusColor),
      _Row(l10n.catalogLastSync, fmtDate(state.localSyncDate)),
      _Row(l10n.catalogServerUpdated, fmtDate(state.serverLastUpdate)),
      _Row(l10n.catalogHoursFromSync, _hoursFrom(state.localSyncDate, l10n)),
      _Row(
        l10n.catalogItemsLabel,
        totalItems > 0 ? NumberFormat('#,###').format(totalItems) : '—',
      ),
      _Row(l10n.catalogValidity, validityText),
    ];
  }

  (String, Color) _status(AppLocalizations l10n, ColorScheme scheme) {
    if (state.isSyncing) return (l10n.catalogStatusSyncing, scheme.primary);
    if (state.hasError) return (l10n.catalogStatusFailed, scheme.error);
    if (state.isUpdateAvailable) {
      return (l10n.catalogStatusUpdateAvailable, const Color(0xFFF59E0B));
    }
    if (state.localSyncDate != null) {
      return (l10n.catalogStatusUpToDate, const Color(0xFF4CAF50));
    }
    return (l10n.catalogNever, scheme.onSurfaceVariant);
  }

  String _hoursFrom(DateTime? d, AppLocalizations l10n) {
    if (d == null) return '—';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return l10n.catalogJustNow;
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}

class _Row {
  const _Row(this.label, this.value, {this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.row});
  final _Row row;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KioskTokens.spaceM,
        vertical: KioskTokens.spaceS,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              row.label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          const SizedBox(width: KioskTokens.spaceM),
          Flexible(
            child: Text(
              row.value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: row.valueColor ?? scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress section ────────────────────────────────────────────────────

class _SyncProgressSection extends StatelessWidget {
  const _SyncProgressSection({required this.state});
  final CatalogState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final data = state.syncProgress;
    final inProgress = state.isSyncing;

    final isNoChange = data?.isCompleted == true &&
        (data?.result?.wasAlreadyUpToDate ?? false);
    final isError = !inProgress && data?.status == CatalogSyncStatus.error;
    // A finished successful sync is not shown as a lingering 100% bar — at rest
    // we fall back to idle ("Press Sync to start"); the info card's Status row
    // already reflects "Up to date". Only an error is surfaced here at rest.
    final isIdle = !inProgress && !isNoChange && !isError;

    late final Color accent;
    late final IconData icon;
    late final bool spinning;
    late final String header;
    late final String message;
    late final double progress;
    late final bool indeterminate;

    if (isNoChange) {
      accent = scheme.onSurfaceVariant;
      icon = Icons.info_outline_rounded;
      spinning = false;
      header = l10n.catalogStatusUpToDate;
      message = l10n.catalogNoNewData;
      progress = 0;
      indeterminate = false;
    } else if (isError) {
      accent = scheme.error;
      icon = Icons.error_outline_rounded;
      spinning = false;
      header = l10n.catalogStatusFailed;
      message = data?.statusMessage ?? state.error ?? l10n.catalogStatusFailed;
      progress = 0;
      indeterminate = false;
    } else if (isIdle) {
      accent = scheme.onSurfaceVariant;
      icon = Icons.sync_rounded;
      spinning = false;
      header = l10n.catalogProgress;
      // Once we've checked and there's no newer catalog, say so; otherwise
      // prompt the user to start a sync.
      final noUpdate =
          !state.isUpdateAvailable && state.serverLastUpdate != null;
      message =
          noUpdate ? l10n.catalogStatusNoUpdate : l10n.catalogPressSyncToStart;
      progress = 0;
      indeterminate = false;
    } else {
      accent = scheme.primary;
      icon = Icons.sync_rounded;
      spinning = true;
      header = l10n.catalogStatusSyncing;
      message = data?.statusMessage ?? l10n.catalogStatusSyncing;
      progress = (data?.progress ?? 0).clamp(0.0, 1.0);
      indeterminate = progress == 0;
    }

    final percent = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _MaybeSpinning(spinning: spinning, child: Icon(icon, color: accent)),
            const SizedBox(width: KioskTokens.spaceS),
            Expanded(
              child: Text(
                header,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (!isIdle && !isNoChange && !isError)
              Text(
                '$percent%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
              ),
          ],
        ),
        const SizedBox(height: KioskTokens.spaceS),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: indeterminate ? null : progress,
            minHeight: 10,
            valueColor: AlwaysStoppedAnimation<Color>(accent),
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: KioskTokens.spaceXS),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _MaybeSpinning extends StatefulWidget {
  const _MaybeSpinning({required this.spinning, required this.child});
  final bool spinning;
  final Widget child;

  @override
  State<_MaybeSpinning> createState() => _MaybeSpinningState();
}

class _MaybeSpinningState extends State<_MaybeSpinning>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.spinning) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant _MaybeSpinning old) {
    super.didUpdateWidget(old);
    if (widget.spinning && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.spinning && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.spinning ? RotationTransition(turns: _c, child: widget.child) : widget.child;
}

// ── Sync button ─────────────────────────────────────────────────────────

class _SyncButton extends ConsumerWidget {
  const _SyncButton({required this.state});
  final CatalogState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final inProgress = state.isSyncing;
    final hasError = state.hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: KioskTokens.touchTargetLarge,
          child: FilledButton(
            onPressed: inProgress
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    ref
                        .read(catalogSyncControllerProvider.notifier)
                        .syncCatalog();
                  },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (inProgress) ...[
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: KioskTokens.spaceS),
                ],
                Text(
                  (inProgress
                          ? l10n.catalogStatusSyncing
                          : (hasError
                              ? l10n.catalogRetrySync
                              : l10n.catalogSyncNow))
                      .toUpperCase(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ),
        if (hasError && !inProgress) ...[
          const SizedBox(height: KioskTokens.spaceS),
          Text(
            state.error ?? l10n.catalogStatusFailed,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ],
    );
  }
}

class _NoCatalogNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Icon(Icons.info_outline_rounded, color: scheme.onSurfaceVariant),
        const SizedBox(width: KioskTokens.spaceS),
        Expanded(
          child: Text(
            l10n.catalogNotAvailable,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}
