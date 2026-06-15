import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../rfid/data/rfid_reader_controller.dart';
import '../../rfid/domain/reader_event.dart';
import '../../rfid/domain/reader_status.dart';
import '../data/session_controller.dart';
import '../domain/cart_item.dart';
import 'product_card.dart';

class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _Header(
                itemCount: session.itemCount,
                onSimulateScan: () {
                  HapticFeedback.lightImpact();
                  ref.read(sessionControllerProvider.notifier).simulateScan();
                },
              ),
              Expanded(
                child: session.isEmpty
                    ? const _EmptyState()
                    : _ProductList(items: session.items),
              ),
              _Footer(
                total: session.total,
                originalTotal: session.originalTotal,
                savings: session.savings,
                isEmpty: session.isEmpty,
                itemCount: session.itemCount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.itemCount,
    required this.onSimulateScan,
  });
  final int itemCount;
  final VoidCallback onSimulateScan;

  static const double _appBarHeight = 96;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final titleStyle = Theme.of(context).textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.w700,
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
                  Icon(
                    Icons.shopping_basket_rounded,
                    size: 64,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: KioskTokens.spaceM),
                  Flexible(
                    child: Text(
                      l10n.yourBag,
                      style: titleStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (itemCount > 0) ...[
                    const SizedBox(width: KioskTokens.spaceM),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      constraints: const BoxConstraints(minWidth: 72),
                      alignment: Alignment.center,
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
                        '$itemCount',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _SimulateScanButton(onPressed: onSimulateScan),
                const SizedBox(width: KioskTokens.spaceS),
                _ScanIndicator(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SimulateScanButton extends StatelessWidget {
  const _SimulateScanButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: l10n.simulateScan,
      child: Material(
        color: scheme.tertiary,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              Icons.touch_app_rounded,
              color: scheme.onTertiary,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanIndicator extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ScanIndicator> createState() => _ScanIndicatorState();
}

class _ScanIndicatorState extends ConsumerState<_ScanIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  late final AnimationController _spinController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final AnimationController _flashController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  ProviderSubscription<AsyncValue<ReaderEvent>>? _eventSub;

  @override
  void initState() {
    super.initState();
    _syncAnimations(ref.read(rfidReaderControllerProvider).status);
    _eventSub = ref.listenManual<AsyncValue<ReaderEvent>>(
      rfidReaderEventsProvider,
      (_, next) {
        final ev = next.value;
        if (ev is ReaderTagsEvent && ev.tags.isNotEmpty) {
          _flashController.forward(from: 0);
        }
      },
    );
  }

  @override
  void dispose() {
    _eventSub?.close();
    _pulseController.dispose();
    _spinController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  void _syncAnimations(ReaderStatus status) {
    if (status == ReaderStatus.reading) {
      if (!_pulseController.isAnimating) _pulseController.repeat();
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
    if (status == ReaderStatus.connecting) {
      if (!_spinController.isAnimating) _spinController.repeat();
    } else {
      _spinController.stop();
      _spinController.value = 0;
    }
  }

  ({Color ring, Color bg, Color fg, IconData icon}) _visualsFor(
    ReaderStatus status,
    ColorScheme scheme,
  ) {
    switch (status) {
      case ReaderStatus.reading:
        return (
          ring: const Color(0xFF2E7D32),
          bg: const Color(0xFFC8E6C9),
          fg: const Color(0xFF1B5E20),
          icon: Icons.nfc_rounded,
        );
      case ReaderStatus.connected:
      case ReaderStatus.idle:
        return (
          ring: scheme.primary,
          bg: scheme.primaryContainer,
          fg: scheme.onPrimaryContainer,
          icon: Icons.nfc_rounded,
        );
      case ReaderStatus.connecting:
        return (
          ring: const Color(0xFFB8860B),
          bg: const Color(0xFFFFE0B2),
          fg: const Color(0xFF8B5A00),
          icon: Icons.sync_rounded,
        );
      case ReaderStatus.error:
        return (
          ring: scheme.error,
          bg: scheme.errorContainer,
          fg: scheme.onErrorContainer,
          icon: Icons.error_outline_rounded,
        );
      case ReaderStatus.offline:
      case ReaderStatus.disconnected:
        return (
          ring: scheme.outline,
          bg: scheme.surfaceContainerHigh,
          fg: scheme.onSurfaceVariant,
          icon: Icons.nfc_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = ref.watch(
      rfidReaderControllerProvider.select((s) => s.status),
    );
    _syncAnimations(status);
    final visuals = _visualsFor(status, scheme);
    final isReading = status == ReaderStatus.reading;
    final isConnecting = status == ReaderStatus.connecting;

    return Tooltip(
      message: _tooltipFor(status),
      child: SizedBox(
        width: 96,
        height: 96,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _pulseController,
            _spinController,
            _flashController,
          ]),
          builder: (context, _) => Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (isReading)
                for (int i = 0; i < 3; i++)
                  Opacity(
                    opacity:
                        (1 - ((_pulseController.value + i / 3) % 1))
                            .clamp(0.0, 0.6),
                    child: Container(
                      width: 56 +
                          ((_pulseController.value + i / 3) % 1) * 32,
                      height: 56 +
                          ((_pulseController.value + i / 3) % 1) * 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: visuals.ring, width: 2),
                      ),
                    ),
                  ),
              if (_flashController.value > 0)
                Container(
                  width: 56 + _flashController.value * 24,
                  height: 56 + _flashController.value * 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: visuals.ring.withValues(
                      alpha: (1 - _flashController.value) * 0.35,
                    ),
                  ),
                ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: visuals.bg,
                  shape: BoxShape.circle,
                ),
                child: Transform.rotate(
                  angle: isConnecting ? _spinController.value * 2 * 3.1416 : 0,
                  child: Icon(
                    visuals.icon,
                    color: visuals.fg,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _tooltipFor(ReaderStatus status) {
    switch (status) {
      case ReaderStatus.reading:
        return 'RFID reading';
      case ReaderStatus.connected:
      case ReaderStatus.idle:
        return 'RFID connected';
      case ReaderStatus.connecting:
        return 'RFID connecting…';
      case ReaderStatus.error:
        return 'RFID error';
      case ReaderStatus.offline:
        return 'RFID offline';
      case ReaderStatus.disconnected:
        return 'RFID disconnected';
    }
  }
}

class _EmptyState extends StatefulWidget {
  const _EmptyState();

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState> {
  static const _hintImageAsset = 'assets/images/rfid_bin_hint.png';
  static const double _illustrationSize = 320;

  bool _hintImageAvailable = false;

  @override
  void initState() {
    super.initState();
    _resolveHintImage();
  }

  void _resolveHintImage() {
    const provider = AssetImage(_hintImageAsset);
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (mounted) setState(() => _hintImageAvailable = true);
        stream.removeListener(listener);
      },
      onError: (_, _) => stream.removeListener(listener),
    );
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final Widget illustration = _hintImageAvailable
        ? Image.asset(_hintImageAsset, fit: BoxFit.contain)
        : DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_basket_rounded,
              size: _illustrationSize * 0.5,
              color: scheme.onSurfaceVariant,
            ),
          );
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KioskTokens.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: _illustrationSize,
              height: _illustrationSize,
              child: illustration,
            ),
            const SizedBox(height: KioskTokens.spaceXL),
            Text(
              l10n.bagEmpty,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KioskTokens.spaceL),
            Text(
              l10n.bagEmptyHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductList extends ConsumerWidget {
  const _ProductList({required this.items});
  final List<CartItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: KioskTokens.spaceL,
        vertical: KioskTokens.spaceS,
      ),
      itemCount: items.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: KioskTokens.spaceS),
      itemBuilder: (_, index) {
        final item = items[index];
        return ProductCard(
          key: ValueKey(item.lineId),
          item: item,
          onRemove: () => ref
              .read(sessionControllerProvider.notifier)
              .removeItem(item.lineId),
        );
      },
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({
    required this.total,
    required this.originalTotal,
    required this.savings,
    required this.isEmpty,
    required this.itemCount,
  });
  final double total;
  final double originalTotal;
  final double savings;
  final bool isEmpty;
  final int itemCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final fmt = NumberFormat.simpleCurrency(
      locale: Localizations.localeOf(context).toString(),
      name: 'ILS',
    );
    final hasSavings = savings > 0.005;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        KioskTokens.spaceL,
        KioskTokens.spaceM,
        KioskTokens.spaceL,
        KioskTokens.spaceL,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(KioskTokens.radiusLarge),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, -8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasSavings) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  l10n.subtotal,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  fmt.format(originalTotal),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.lineThrough,
                      ),
                ),
              ],
            ),
            const SizedBox(height: KioskTokens.spaceXS),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  l10n.youSavedLabel,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '-${fmt.format(savings)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: KioskTokens.spaceS),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                l10n.total,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              AnimatedSwitcher(
                duration: KioskTokens.motionMedium,
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Text(
                  fmt.format(total),
                  key: ValueKey(total),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KioskTokens.spaceM),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _confirmCancel(context, ref),
                  icon: const Icon(Icons.close_rounded),
                  label: Text(l10n.cancel.toUpperCase()),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  ),
                ),
              ),
              const SizedBox(width: KioskTokens.spaceS),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: isEmpty
                      ? null
                      : () => _confirmQuantity(context),
                  icon: const Icon(Icons.lock_rounded),
                  label: Text(l10n.checkout.toUpperCase()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final scheme = theme.colorScheme;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: KioskTokens.spaceXL,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KioskTokens.radiusLarge),
          ),
          backgroundColor: scheme.surface,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                KioskTokens.spaceXL,
                KioskTokens.spaceXL,
                KioskTokens.spaceXL,
                KioskTokens.spaceL,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.remove_shopping_cart_rounded,
                      size: 48,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: KioskTokens.spaceL),
                  Text(
                    l10n.cancelSessionTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: KioskTokens.spaceM),
                  Text(
                    l10n.cancelSessionBody,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: KioskTokens.spaceXL),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    icon: const Icon(Icons.arrow_back_rounded,
                        size: 28, color: Colors.white),
                    label: Text(
                      l10n.keepShopping.toUpperCase(),
                      style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                    ),
                    style: FilledButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: KioskTokens.spaceS),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 28, color: Colors.white),
                    label: Text(
                      l10n.cancelSession.toUpperCase(),
                      style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (result == true && context.mounted) {
      ref.read(sessionControllerProvider.notifier).reset();
      context.go(AppRoutes.home);
    }
  }

  Future<void> _confirmQuantity(BuildContext context) async {
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final scheme = theme.colorScheme;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: KioskTokens.spaceXL,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KioskTokens.radiusLarge),
          ),
          backgroundColor: scheme.surface,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                KioskTokens.spaceXL,
                KioskTokens.spaceXL,
                KioskTokens.spaceXL,
                KioskTokens.spaceL,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      size: 48,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: KioskTokens.spaceL),
                  Text(
                    l10n.confirmQtyTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: KioskTokens.spaceM),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KioskTokens.spaceL,
                      vertical: KioskTokens.spaceM,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainer,
                      borderRadius:
                          BorderRadius.circular(KioskTokens.radiusMedium),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$itemCount',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displayLarge?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: KioskTokens.spaceXS),
                        Text(
                          l10n.confirmQtyBody(itemCount),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: KioskTokens.spaceXL),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    icon: const Icon(Icons.check_rounded,
                        size: 28, color: Colors.white),
                    label: Text(
                      l10n.confirmQtyConfirm.toUpperCase(),
                      style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                    ),
                    style: FilledButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: KioskTokens.spaceS),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    icon: Icon(Icons.arrow_back_rounded,
                        size: 28, color: scheme.onSurface),
                    label: Text(
                      l10n.confirmQtyBack.toUpperCase(),
                      style: theme.textTheme.titleLarge?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.surfaceContainerHigh,
                      foregroundColor: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (result == true && context.mounted) {
      HapticFeedback.mediumImpact();
      context.go(AppRoutes.checkout);
    }
  }
}

