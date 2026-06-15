import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/format/currency.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cancel_session_dialog.dart';
import '../../../core/widgets/idle_timeout_detector.dart';
import '../../../core/widgets/idle_warning_dialog.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/product.dart';
import '../../member/data/member_controller.dart';
import '../../rfid/data/rfid_reader_controller.dart';
import '../../rfid/domain/reader_event.dart';
import '../../rfid/domain/reader_status.dart';
import '../data/session_controller.dart';
import '../domain/cart_item.dart';
import 'product_card.dart';

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  /// After this much wall-clock inactivity, the warning dialog is shown.
  static const Duration _idleTimeout = Duration(minutes: 1);

  /// Guard against re-entrant timeouts firing while the warning is already
  /// on screen.
  bool _warningOpen = false;

  Future<void> _onIdleTimeout() async {
    if (_warningOpen) return;
    // setState so the wrapping IdleTimeoutDetector rebuilds with the new
    // `enabled` value — otherwise it never sees the dialog open/close and
    // the idle timer doesn't restart after the user dismisses the warning.
    setState(() => _warningOpen = true);
    try {
      final keepShopping = await showIdleWarningDialog(context);
      if (!mounted) return;
      if (!keepShopping) {
        // User didn't respond — end the session and return to home.
        ref.read(sessionControllerProvider.notifier).reset();
        context.go(AppRoutes.home);
      }
    } finally {
      if (mounted) setState(() => _warningOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);

    return PopScope(
      canPop: false,
      child: IdleTimeoutDetector(
        // Pause idle tracking while the warning modal is up — the modal owns
        // its own timer at that point.
        enabled: !_warningOpen,
        timeout: _idleTimeout,
        onTimeout: _onIdleTimeout,
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
                  saleDiscountAmount: session.saleDiscountAmount,
                  memberDiscountPct: session.memberDiscountPct,
                  memberDiscountAmount: session.memberDiscountAmount,
                  isEmpty: session.isEmpty,
                  itemCount: session.itemCount,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.itemCount, required this.onSimulateScan});
  final int itemCount;
  final VoidCallback onSimulateScan;

  static const double _appBarHeight = 96;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final member = ref.watch(memberControllerProvider).member;
    final greetingName = member == null
        ? null
        : (member.firstName.isNotEmpty ? member.firstName : member.fullName);
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
                  Icon(
                    greetingName != null
                        ? Icons.card_membership_rounded
                        : Icons.shopping_basket_rounded,
                    size: 64,
                    color: greetingName != null
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: KioskTokens.spaceM),
                  Flexible(
                    child: Text(
                      greetingName != null
                          ? l10n.memberWelcome(greetingName)
                          : l10n.yourBag,
                      style: titleStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (itemCount > 0) ...[
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
                        l10n.itemsCount(itemCount),
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
                    opacity: (1 - ((_pulseController.value + i / 3) % 1)).clamp(
                      0.0,
                      0.6,
                    ),
                    child: Container(
                      width: 56 + ((_pulseController.value + i / 3) % 1) * 32,
                      height: 56 + ((_pulseController.value + i / 3) % 1) * 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: visuals.ring, width: 2),
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
                  child: Icon(visuals.icon, color: visuals.fg, size: 28),
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
    listener = ImageStreamListener((info, _) {
      if (mounted) setState(() => _hintImageAvailable = true);
      stream.removeListener(listener);
    }, onError: (_, _) => stream.removeListener(listener));
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
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w800),
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
    required this.saleDiscountAmount,
    required this.memberDiscountPct,
    required this.memberDiscountAmount,
    required this.isEmpty,
    required this.itemCount,
  });
  final double total;
  final double originalTotal;
  final double saleDiscountAmount;
  final double memberDiscountPct;
  final double memberDiscountAmount;
  final bool isEmpty;
  final int itemCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final fmt = CurrencyFormat.of(
      Localizations.localeOf(context).toString(),
      name: 'ILS',
    );
    final hasSaleDiscount = saleDiscountAmount > 0.005;
    final hasMemberDiscount =
        memberDiscountPct > 0 && memberDiscountAmount > 0.005;
    final hasAnyDiscount = hasSaleDiscount || hasMemberDiscount;
    final titleLarge = Theme.of(context).textTheme.titleLarge;

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
          if (hasAnyDiscount) ...[
            // Subtotal + discount lines. The amounts share one IntrinsicWidth
            // column, end-aligned so every amount hugs the panel's trailing edge
            // (decimals line up), while the titles align on the opposite edge
            // above the "Total" title.
            _TotalsBreakdown(
              rows: [
                (
                  label: Text(
                    l10n.subtotal,
                    style: titleLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  amount: Currency.ltr(
                    Text(
                      fmt.format(originalTotal),
                      style: titleLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ),
                if (hasSaleDiscount)
                  (
                    label: Text(
                      l10n.saleDiscountShort,
                      style: titleLarge?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    amount: Currency.ltr(
                      Text(
                        fmt.format(saleDiscountAmount, signed: true),
                        style: titleLarge?.copyWith(
                          color: scheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (hasMemberDiscount)
                  (
                    label: Text(
                      l10n.memberDiscountLineLabel(
                        _formatPercent(memberDiscountPct),
                      ),
                      style: titleLarge?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    amount: Currency.ltr(
                      Text(
                        fmt.format(memberDiscountAmount, signed: true),
                        style: titleLarge?.copyWith(
                          color: scheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                child: Directionality(
                  key: ValueKey(total),
                  textDirection: TextDirection.ltr,
                  child: Text(
                    fmt.format(total),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KioskTokens.spaceM),
          const _BagTile(),
          const SizedBox(height: KioskTokens.spaceM),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _confirmCancel(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.onSurfaceVariant,
                  ),
                  child: Text(l10n.cancel.toUpperCase()),
                ),
              ),
              const SizedBox(width: KioskTokens.spaceS),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: isEmpty
                      ? null
                      : () => _confirmQuantity(context, ref),
                  child: Text(l10n.checkout.toUpperCase()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showCancelSessionDialog(context);
    if (confirmed && context.mounted) {
      ref.read(sessionControllerProvider.notifier).reset();
      context.go(AppRoutes.home);
    }
  }

  Future<void> _confirmQuantity(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context);
    final session = ref.read(sessionControllerProvider);
    final bagCount = session.bagCount;
    final nonBagCount = itemCount - bagCount;

    final result = await showDialog<_ConfirmQtyResult>(
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
                  const SizedBox(height: KioskTokens.spaceL),
                  _ConfirmQtySection(
                    icon: Icons.checkroom_rounded,
                    sectionLabel: l10n.confirmQtyItemsSection,
                    countLabel: l10n.confirmQtyItemsLabel(nonBagCount),
                    bigNumber: '$nonBagCount',
                    accent: scheme.primary,
                  ),
                  const SizedBox(height: KioskTokens.spaceM),
                  if (bagCount > 0)
                    _ConfirmQtySection(
                      icon: Icons.shopping_bag_rounded,
                      sectionLabel: l10n.confirmQtyBagsSection,
                      countLabel: l10n.confirmQtyBagsLabel(bagCount),
                      bigNumber: '$bagCount',
                      accent: scheme.primary,
                    )
                  else
                    _ConfirmQtySection(
                      icon: Icons.shopping_bag_outlined,
                      sectionLabel: l10n.confirmQtyBagsSection,
                      countLabel: l10n.confirmQtyNoBagsTitle,
                      accent: scheme.primary,
                      trailing: FilledButton(
                        onPressed: () =>
                            Navigator.of(ctx).pop(_ConfirmQtyResult.addBag),
                        style: FilledButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: KioskTokens.spaceXL,
                            vertical: KioskTokens.spaceM,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          l10n.confirmQtyNoBagsYes.toUpperCase(),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: KioskTokens.spaceXL),
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(ctx).pop(_ConfirmQtyResult.confirmed),
                    style: FilledButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      l10n.confirmQtyConfirm.toUpperCase(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: KioskTokens.spaceS),
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(ctx).pop(_ConfirmQtyResult.back),
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.surfaceContainerHigh,
                      foregroundColor: scheme.onSurface,
                    ),
                    child: Text(
                      l10n.confirmQtyBack.toUpperCase(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (!context.mounted) return;
    switch (result) {
      case _ConfirmQtyResult.confirmed:
        HapticFeedback.mediumImpact();
        context.go(AppRoutes.checkout);
      case _ConfirmQtyResult.addBag:
        HapticFeedback.selectionClick();
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withValues(alpha: 0.55),
          builder: (_) => const _BagPickerSheet(),
        );
      case _ConfirmQtyResult.back:
      case null:
        break;
    }
  }
}

/// The subtotal + discount lines of the totals panel, laid out as a two-column
/// [Table]. The amounts form one [IntrinsicColumnWidth] column, end-aligned so
/// they hug the panel's trailing edge (decimals line up); the titles sit in the
/// flexible first column, start-aligned on the same edge as the "Total" title.
class _TotalsBreakdown extends StatelessWidget {
  const _TotalsBreakdown({required this.rows});

  final List<({Widget label, Widget amount})> rows;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {0: FlexColumnWidth(), 1: IntrinsicColumnWidth()},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (var i = 0; i < rows.length; i++)
          TableRow(
            children: [
              Padding(
                padding: EdgeInsetsDirectional.only(
                  top: i == 0 ? 0 : KioskTokens.spaceXS,
                  end: KioskTokens.spaceM,
                ),
                // Start-align so every price title lines up on the same edge as
                // the "Total" title in the row below.
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: rows[i].label,
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(
                  top: i == 0 ? 0 : KioskTokens.spaceXS,
                ),
                // Amounts are LTR currency strings (₪465.00). Align them so
                // their *right* edge — the decimals / cents end — is flush with
                // the widest amount's right edge, and the narrower discounts sit
                // directly under the original price with no trailing gap. In the
                // panel's RTL flow the right edge is the directional start; in
                // LTR it is the end. Resolve against an explicit LTR
                // directionality so this reads as "align right" in both.
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: rows[i].amount,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

enum _ConfirmQtyResult { confirmed, back, addBag }

class _ConfirmQtySection extends StatelessWidget {
  const _ConfirmQtySection({
    required this.icon,
    required this.sectionLabel,
    required this.countLabel,
    required this.accent,
    this.bigNumber,
    this.trailing,
  }) : assert(
         bigNumber != null || trailing != null,
         'Provide either bigNumber or trailing',
       );

  final IconData icon;
  final String sectionLabel;
  final String countLabel;
  final Color accent;
  final String? bigNumber;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        KioskTokens.spaceL,
        KioskTokens.spaceM,
        KioskTokens.spaceL,
        KioskTokens.spaceM,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KioskTokens.radiusMedium),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(KioskTokens.radiusSmall),
            ),
            child: Icon(icon, size: 36, color: accent),
          ),
          const SizedBox(width: KioskTokens.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sectionLabel.toUpperCase(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  countLabel,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: KioskTokens.spaceM),
          if (trailing != null)
            trailing!
          else
            Text(
              bigNumber!,
              style: theme.textTheme.displayLarge?.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
                height: 1,
              ),
            ),
        ],
      ),
    );
  }
}

String _formatPercent(double pct) {
  if (pct == pct.roundToDouble()) return pct.toStringAsFixed(0);
  return pct.toStringAsFixed(1);
}

/// Returns the localized display copy for a known bag variant SKU. Falls
/// back to the catalog's English name/description if the SKU isn't one of
/// the seeded variants — so new bag SKUs added later still render (just
/// without localized copy until translations are added).
({String name, String? description}) _localizedBagCopy(
  AppLocalizations l10n,
  Product bag,
) {
  switch (bag.sku) {
    case 'BAG-STD-S-001':
      return (name: l10n.bagSmallName, description: l10n.bagSmallDescription);
    case 'BAG-STD-L-001':
      return (name: l10n.bagLargeName, description: l10n.bagLargeDescription);
    default:
      return (name: bag.name, description: bag.description);
  }
}

/// "Need a bag?" summary tile shown in the session footer. Tapping it opens
/// a modal bottom sheet that lists every bag variant with photos and per-
/// variant quantity steppers. When at least one bag is already in the cart
/// the tile shows a count chip on the right; the modal still drives all
/// add/remove actions.
class _BagTile extends ConsumerWidget {
  const _BagTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogRepositoryProvider);
    final bags = shoppingBagSkus
        .map(catalog.findBySku)
        .whereType<Product>()
        .toList(growable: false);
    if (bags.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final fmt = NumberFormat.simpleCurrency(
      locale: Localizations.localeOf(context).toString(),
      name: 'ILS',
    );
    final cheapest = bags.map((b) => b.price).reduce((a, b) => a < b ? a : b);

    final bagCount = ref.watch(
      sessionControllerProvider.select((s) => s.bagCount),
    );
    final hasBags = bagCount > 0;

    final borderRadius = BorderRadius.circular(KioskTokens.radiusLarge);

    return AnimatedContainer(
      duration: KioskTokens.motionFast,
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasBags
              ? [
                  Color.alphaBlend(
                    scheme.primary.withValues(alpha: 0.10),
                    scheme.surface,
                  ),
                  Color.alphaBlend(
                    scheme.primary.withValues(alpha: 0.04),
                    scheme.surface,
                  ),
                ]
              : [scheme.surface, scheme.surface],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: hasBags ? 0.18 : 0.06),
            blurRadius: hasBags ? 28 : 18,
            spreadRadius: hasBags ? -4 : -6,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            _openBagPicker(context);
          },
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              0,
              0,
              KioskTokens.spaceM,
              0,
            ),
            child: Row(
              children: [
                _BagTileIcon(hasBags: hasBags),
                const SizedBox(width: KioskTokens.spaceS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.bagTileTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              l10n.bagTileSubtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: KioskTokens.spaceXS,
                            ),
                            child: Text(
                              '·',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              l10n.bagTileFromPrice(fmt.format(cheapest)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: KioskTokens.spaceS),
                AnimatedSwitcher(
                  duration: KioskTokens.motionFast,
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: hasBags
                      ? _BagCountBadge(
                          key: const ValueKey('count'),
                          count: bagCount,
                          label: l10n.bagTileInCartBadge(bagCount),
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openBagPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => const _BagPickerSheet(),
    );
  }
}

class _BagTileIcon extends StatelessWidget {
  const _BagTileIcon({required this.hasBags});

  final bool hasBags;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: KioskTokens.motionFast,
      curve: Curves.easeOut,
      width: 88,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasBags
              ? [scheme.primary, scheme.primary.withValues(alpha: 0.82)]
              : [
                  scheme.primaryContainer,
                  Color.alphaBlend(
                    scheme.primary.withValues(alpha: 0.08),
                    scheme.primaryContainer,
                  ),
                ],
        ),
        borderRadius: BorderRadiusDirectional.horizontal(
          start: Radius.circular(KioskTokens.radiusLarge),
        ).resolve(Directionality.of(context)),
        boxShadow: hasBags
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  spreadRadius: -2,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Icon(
        hasBags ? Icons.shopping_bag_rounded : Icons.shopping_bag_outlined,
        color: hasBags ? scheme.onPrimary : scheme.onPrimaryContainer,
        size: 48,
      ),
    );
  }
}

class _BagCountBadge extends StatelessWidget {
  const _BagCountBadge({super.key, required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KioskTokens.spaceM,
        vertical: KioskTokens.spaceXS,
      ),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.35),
            blurRadius: 12,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: theme.textTheme.titleMedium?.copyWith(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w800,
          fontFeatures: const [FontFeature.tabularFigures()],
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Modal bottom sheet listing every bag variant from the catalog with a
/// photo, name, price, and per-variant stepper. Tapping a card's +/- adds
/// or removes that specific SKU from the cart immediately — the sheet is
/// purely a navigational surface, no "save" step is needed since changes
/// are already applied to the session.
class _BagPickerSheet extends ConsumerWidget {
  const _BagPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final fmt = NumberFormat.simpleCurrency(
      locale: Localizations.localeOf(context).toString(),
      name: 'ILS',
    );

    final catalog = ref.watch(catalogRepositoryProvider);
    final bags = shoppingBagSkus
        .map(catalog.findBySku)
        .whereType<Product>()
        .toList(growable: false);

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(KioskTokens.radiusLarge),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KioskTokens.spaceL,
                KioskTokens.spaceL,
                KioskTokens.spaceL,
                KioskTokens.spaceM,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.bagPickerTitle,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: KioskTokens.spaceXS),
                        Text(
                          l10n.bagPickerSubtitle,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: KioskTokens.spaceS),
                  IconButton(
                    tooltip: l10n.bagPickerClose,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      size: 32,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: scheme.outlineVariant),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(KioskTokens.spaceL),
                itemCount: bags.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: KioskTokens.spaceM),
                itemBuilder: (_, index) =>
                    _BagVariantCard(bag: bags[index], fmt: fmt, l10n: l10n),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  KioskTokens.spaceL,
                  KioskTokens.spaceS,
                  KioskTokens.spaceL,
                  KioskTokens.spaceL,
                ),
                child: SizedBox(
                  height: KioskTokens.touchTargetLarge,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      l10n.bagPickerDone.toUpperCase(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BagVariantCard extends ConsumerWidget {
  const _BagVariantCard({
    required this.bag,
    required this.fmt,
    required this.l10n,
  });

  final Product bag;
  final NumberFormat fmt;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final copy = _localizedBagCopy(l10n, bag);
    final count = ref.watch(
      sessionControllerProvider.select((s) => s.countOfBagSku(bag.sku)),
    );
    final canRemove = count > 0;

    Color fallback;
    try {
      final hex = bag.colorHex.replaceFirst('#', '');
      fallback = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      fallback = scheme.primaryContainer;
    }

    final hasCount = count > 0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(KioskTokens.radiusLarge),
        border: Border.all(
          color: hasCount
              ? scheme.primary.withValues(alpha: 0.55)
              : scheme.outlineVariant.withValues(alpha: 0.6),
          width: hasCount ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: hasCount ? 0.14 : 0.05),
            blurRadius: hasCount ? 24 : 14,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(KioskTokens.spaceM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 1,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          KioskTokens.radiusMedium,
                        ),
                        child: ColoredBox(
                          color: fallback.withValues(alpha: 0.18),
                          child: bag.imageUrl.isNotEmpty
                              ? Image.network(
                                  bag.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Center(
                                    child: Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 72,
                                      color: fallback,
                                    ),
                                  ),
                                  loadingBuilder: (ctx, child, p) => p == null
                                      ? child
                                      : Center(
                                          child: SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              color: fallback,
                                            ),
                                          ),
                                        ),
                                )
                              : Center(
                                  child: Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 72,
                                    color: fallback,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: KioskTokens.spaceM),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          copy.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        if (copy.description != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            copy.description!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                        const SizedBox(height: KioskTokens.spaceS),
                        Text(
                          l10n.bagTileEach(fmt.format(bag.price)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KioskTokens.spaceM),
            SizedBox(
              width: double.infinity,
              child: _BagStepper(
                count: count,
                canRemove: canRemove,
                fullWidth: true,
                onAdd: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(sessionControllerProvider.notifier)
                      .addBagBySku(bag.sku);
                },
                onRemove: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(sessionControllerProvider.notifier)
                      .removeBagBySku(bag.sku);
                },
                decreaseLabel: l10n.bagTileDecrease,
                increaseLabel: l10n.bagTileIncrease,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BagStepper extends StatelessWidget {
  const _BagStepper({
    required this.count,
    required this.canRemove,
    required this.onAdd,
    required this.onRemove,
    required this.decreaseLabel,
    required this.increaseLabel,
    this.fullWidth = false,
  });

  final int count;
  final bool canRemove;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final String decreaseLabel;
  final String increaseLabel;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final countWidget = Text(
      '$count',
      style: theme.textTheme.displaySmall?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w800,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    return Directionality(
      // Keep [-] count [+] in a fixed visual order regardless of locale
      // direction; the numeric stepper reads more cleanly left-to-right.
      textDirection: TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.all(6),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            _StepperButton(
              icon: Icons.remove_rounded,
              onPressed: canRemove ? onRemove : null,
              tooltip: decreaseLabel,
            ),
            if (fullWidth)
              Expanded(child: Center(child: countWidget))
            else
              SizedBox(width: 96, child: Center(child: countWidget)),
            _StepperButton(
              icon: Icons.add_rounded,
              onPressed: onAdd,
              tooltip: increaseLabel,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled ? scheme.primary : scheme.surfaceContainer,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 72,
            height: 72,
            child: Icon(
              icon,
              color: enabled
                  ? scheme.onPrimary
                  : scheme.onSurfaceVariant.withValues(alpha: 0.4),
              size: 36,
            ),
          ),
        ),
      ),
    );
  }
}
