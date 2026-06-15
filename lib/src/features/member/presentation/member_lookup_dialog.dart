import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/idle_timeout_detector.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/member_controller.dart';
import '../domain/member.dart';
import '../domain/member_state.dart';

/// Result returned by [showMemberLookupDialog].
///
/// - `true`  → start session (member attached or user pressed Skip)
/// - `false` → user dismissed the dialog without committing to a session
enum MemberLookupOutcome { attached, skipped, cancelled }

/// Displays the membership lookup modal. Returns once the user has either:
///   * successfully attached a member ([MemberLookupOutcome.attached])
///   * chosen to skip and continue as a guest ([MemberLookupOutcome.skipped])
///   * dismissed the dialog without proceeding ([MemberLookupOutcome.cancelled])
Future<MemberLookupOutcome> showMemberLookupDialog(BuildContext context) async {
  final result = await showDialog<MemberLookupOutcome>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (_) => const _MemberLookupDialog(),
  );
  return result ?? MemberLookupOutcome.cancelled;
}

class _MemberLookupDialog extends ConsumerStatefulWidget {
  const _MemberLookupDialog();

  @override
  ConsumerState<_MemberLookupDialog> createState() =>
      _MemberLookupDialogState();
}

class _MemberLookupDialogState extends ConsumerState<_MemberLookupDialog> {
  static const int _maxLength = 16;

  String _input = '';

  void _appendDigit(String d) {
    if (_input.length >= _maxLength) return;
    HapticFeedback.selectionClick();
    setState(() => _input = '$_input$d');
  }

  void _backspace() {
    if (_input.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _clearInput() {
    if (_input.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _input = '');
  }

  Future<void> _submit() async {
    if (_input.isEmpty) return;
    HapticFeedback.mediumImpact();
    final ok = await ref.read(memberControllerProvider.notifier).lookup(_input);
    if (!mounted) return;
    if (ok) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void _skip() {
    HapticFeedback.lightImpact();
    ref.read(memberControllerProvider.notifier).clear();
    Navigator.of(context).pop(MemberLookupOutcome.skipped);
  }

  void _cancel() {
    HapticFeedback.lightImpact();
    ref.read(memberControllerProvider.notifier).clear();
    Navigator.of(context).pop(MemberLookupOutcome.cancelled);
  }

  void _retry() {
    HapticFeedback.selectionClick();
    ref.read(memberControllerProvider.notifier).clear();
    // Keep the input so the user can edit it instead of retyping.
  }

  void _continueAttached() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(MemberLookupOutcome.attached);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final memberState = ref.watch(memberControllerProvider);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: KioskTokens.spaceXL,
        vertical: KioskTokens.spaceL,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KioskTokens.radiusLarge),
      ),
      backgroundColor: scheme.surface,
      child: IdleTimeoutDetector(
        // Pause the timer while a lookup is in flight so a slow server can't
        // dismiss the modal mid-request.
        enabled: memberState.status != MemberStatus.looking,
        timeout: const Duration(minutes: 1),
        onTimeout: _cancel,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KioskTokens.spaceXL,
              KioskTokens.spaceXL,
              KioskTokens.spaceXL,
              KioskTokens.spaceL,
            ),
            child: AnimatedSwitcher(
              duration: KioskTokens.motionMedium,
              // Outgoing views disappear instantly so the user doesn't see the
              // old view ghosting on top of the new one during the cross-fade.
              // Only the incoming view animates.
              reverseDuration: Duration.zero,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              // Size to the *current* child only so the dialog adopts the new
              // view's height immediately rather than measuring the union of
              // outgoing + incoming children (which makes the dialog briefly
              // taller during a fade from the keypad view to the smaller
              // searching/attached/not-found views).
              layoutBuilder: (currentChild, previousChildren) {
                // Stack sizes to the current (new) child, so the dialog snaps
                // to the new view's natural height immediately. Outgoing
                // children keep their own (potentially larger) intrinsic size
                // while fading out — we position them at top-left without
                // forcing them to fit, and clip so they don't bleed past the
                // dialog edges.
                return ClipRect(
                  child: Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.hardEdge,
                    children: [
                      ...previousChildren.map(
                        (c) => Positioned(top: 0, left: 0, right: 0, child: c),
                      ),
                      ?currentChild,
                    ],
                  ),
                );
              },
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(memberState.status),
                child: _buildBody(theme, memberState),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, MemberStateData state) {
    switch (state.status) {
      case MemberStatus.looking:
        return _LookingView(query: state.lastQuery ?? _input);
      case MemberStatus.attached:
        return _AttachedView(
          member: state.member!,
          onContinue: _continueAttached,
        );
      case MemberStatus.notFound:
      case MemberStatus.error:
        return _NotFoundView(
          query: state.lastQuery ?? _input,
          message: state.errorMessage,
          onRetry: _retry,
          onSkip: _skip,
        );
      case MemberStatus.idle:
        return _InputView(
          input: _input,
          onDigit: _appendDigit,
          onBackspace: _backspace,
          onClear: _clearInput,
          onSubmit: _submit,
          onSkip: _skip,
          onCancel: _cancel,
        );
    }
  }
}

class _InputView extends StatelessWidget {
  const _InputView({
    required this.input,
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
    required this.onSubmit,
    required this.onSkip,
    required this.onCancel,
  });

  final String input;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onSubmit;
  final VoidCallback onSkip;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final hasInput = input.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.card_membership_rounded,
              size: 48,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: KioskTokens.spaceL),
        Text(
          l10n.memberLookupTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: KioskTokens.spaceS),
        Text(
          l10n.memberLookupSubtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: KioskTokens.spaceL),
        _InputDisplay(input: input, placeholder: l10n.memberInputPlaceholder),
        const SizedBox(height: KioskTokens.spaceL),
        _Keypad(
          onDigit: onDigit,
          onBackspace: onBackspace,
          onClear: onClear,
          canClear: hasInput,
        ),
        const SizedBox(height: KioskTokens.spaceL),
        SizedBox(
          height: KioskTokens.touchTargetLarge,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.onSurfaceVariant,
                  ),
                  child: Text(
                    l10n.cancel.toUpperCase(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: KioskTokens.spaceS),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: hasInput ? onSubmit : onSkip,
                  style: FilledButton.styleFrom(foregroundColor: Colors.white),
                  child: Text(
                    (hasInput ? l10n.memberNext : l10n.memberSkip)
                        .toUpperCase(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InputDisplay extends StatelessWidget {
  const _InputDisplay({required this.input, required this.placeholder});

  final String input;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isEmpty = input.isEmpty;
    return Container(
      height: 88,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: KioskTokens.spaceL),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KioskTokens.radiusMedium),
        border: Border.all(
          color: isEmpty ? scheme.outlineVariant : scheme.primary,
          width: isEmpty ? 1 : 2,
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            isEmpty ? placeholder : input,
            maxLines: 1,
            style: theme.textTheme.displayMedium?.copyWith(
              color: isEmpty
                  ? scheme.onSurfaceVariant.withValues(alpha: 0.5)
                  : scheme.onSurface,
              fontWeight: isEmpty ? FontWeight.w500 : FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: isEmpty ? 0 : 4,
            ),
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
    required this.canClear,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final bool canClear;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          _row(['1', '2', '3']),
          const SizedBox(height: KioskTokens.spaceS),
          _row(['4', '5', '6']),
          const SizedBox(height: KioskTokens.spaceS),
          _row(['7', '8', '9']),
          const SizedBox(height: KioskTokens.spaceS),
          Row(
            children: [
              Expanded(
                child: _KeyButton.action(
                  icon: Icons.refresh_rounded,
                  onPressed: canClear ? onClear : null,
                ),
              ),
              const SizedBox(width: KioskTokens.spaceS),
              Expanded(
                child: _KeyButton.digit('0', onPressed: () => onDigit('0')),
              ),
              const SizedBox(width: KioskTokens.spaceS),
              Expanded(
                child: _KeyButton.action(
                  icon: Icons.backspace_rounded,
                  onPressed: canClear ? onBackspace : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(List<String> digits) {
    return Row(
      children: [
        for (var i = 0; i < digits.length; i++) ...[
          if (i > 0) const SizedBox(width: KioskTokens.spaceS),
          Expanded(
            child: _KeyButton.digit(
              digits[i],
              onPressed: () => onDigit(digits[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton._({this.label, this.icon, required this.onPressed});

  factory _KeyButton.digit(String label, {required VoidCallback onPressed}) =>
      _KeyButton._(label: label, onPressed: onPressed);

  factory _KeyButton.action({
    required IconData icon,
    required VoidCallback? onPressed,
  }) => _KeyButton._(icon: icon, onPressed: onPressed);

  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = onPressed != null;
    final isDigit = label != null;
    return SizedBox(
      height: 84,
      child: Material(
        color: isDigit ? scheme.surfaceContainerHigh : scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KioskTokens.radiusMedium),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Center(
            child: isDigit
                ? Text(
                    label!,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  )
                : Icon(
                    icon,
                    size: 32,
                    color: enabled
                        ? scheme.onSurfaceVariant
                        : scheme.onSurfaceVariant.withValues(alpha: 0.35),
                  ),
          ),
        ),
      ),
    );
  }
}

class _LookingView extends StatelessWidget {
  const _LookingView({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: _SearchingIndicator()),
        const SizedBox(height: KioskTokens.spaceL),
        Text(
          l10n.memberLooking,
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: KioskTokens.spaceS),
        Text(
          query,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: KioskTokens.spaceXL),
      ],
    );
  }
}

class _SearchingIndicator extends StatefulWidget {
  const _SearchingIndicator();

  @override
  State<_SearchingIndicator> createState() => _SearchingIndicatorState();
}

class _SearchingIndicatorState extends State<_SearchingIndicator>
    with TickerProviderStateMixin {
  static const double _size = 128;
  static const double _coreSize = 64;

  late final AnimationController _arc = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  late final AnimationController _icon = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _arc.dispose();
    _pulse.dispose();
    _icon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: _size,
      height: _size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_arc, _pulse, _icon]),
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Expanding pulse rings — three offset waves give a continuous feel.
              for (int i = 0; i < 3; i++)
                _PulseRing(
                  progress: (_pulse.value + i / 3) % 1,
                  maxSize: _size,
                  minSize: _coreSize,
                  color: scheme.primary,
                ),
              // Rotating accent arc tracing the outer ring.
              CustomPaint(
                size: const Size(_size - 8, _size - 8),
                painter: _ArcPainter(
                  rotation: _arc.value * 2 * math.pi,
                  color: scheme.primary,
                  strokeWidth: 5,
                  sweep: math.pi * 0.55,
                ),
              ),
              // Solid core circle.
              Container(
                width: _coreSize,
                height: _coreSize,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.25),
                      blurRadius: 18,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Transform.scale(
                  // Subtle breathing on the icon (0.92 → 1.08).
                  scale: 0.92 + (_icon.value * 0.16),
                  child: Icon(
                    Icons.search_rounded,
                    size: 36,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({
    required this.progress,
    required this.maxSize,
    required this.minSize,
    required this.color,
  });

  final double progress;
  final double maxSize;
  final double minSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = minSize + (maxSize - minSize) * progress;
    // Fade out as the ring expands; clamp keeps the very-fresh ring just below
    // full opacity so it doesn't overwhelm the core.
    final opacity = (1 - progress).clamp(0.0, 0.55);
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: opacity), width: 2),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.rotation,
    required this.color,
    required this.strokeWidth,
    required this.sweep,
  });

  final double rotation;
  final Color color;
  final double strokeWidth;
  final double sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    ).deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: sweep,
        colors: [color.withValues(alpha: 0), color],
        transform: GradientRotation(rotation - math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(rect, rotation - math.pi / 2, sweep, false, paint);
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.rotation != rotation ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.sweep != sweep;
}

String _localizedTierName(AppLocalizations l10n, String code) {
  switch (code.toLowerCase()) {
    case 'gold':
      return l10n.memberTierGold;
    case 'silver':
      return l10n.memberTierSilver;
    case 'platinum':
      return l10n.memberTierPlatinum;
    default:
      return l10n.memberTierStandard;
  }
}

({String label, String? description}) _localizedBenefit(
  AppLocalizations l10n,
  MemberBenefit benefit,
  Member member,
) {
  switch (benefit.code) {
    case 'member_discount':
      return (
        label: l10n.memberBenefitDiscountLabel(
          _formatPercent(member.discountPct),
        ),
        description: l10n.memberBenefitDiscountDescription,
      );
    case 'free_alterations':
      return (
        label: l10n.memberBenefitFreeAlterationsLabel,
        description: l10n.memberBenefitFreeAlterationsDescription,
      );
    case 'birthday_gift':
      return (
        label: l10n.memberBenefitBirthdayGiftLabel,
        description: l10n.memberBenefitBirthdayGiftDescription,
      );
    case 'early_access':
      return (
        label: l10n.memberBenefitEarlyAccessLabel,
        description: l10n.memberBenefitEarlyAccessDescription,
      );
    default:
      return (label: benefit.label, description: benefit.description);
  }
}

String _formatPercent(double pct) {
  if (pct == pct.roundToDouble()) return pct.toStringAsFixed(0);
  return pct.toStringAsFixed(1);
}

class _AttachedView extends StatelessWidget {
  const _AttachedView({required this.member, required this.onContinue});

  final Member member;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final tier = member.tier;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFC8E6C9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 56,
              color: Color(0xFF1B5E20),
            ),
          ),
        ),
        const SizedBox(height: KioskTokens.spaceL),
        Text(
          l10n.memberAttachedTitle(
            member.firstName.isNotEmpty ? member.firstName : member.fullName,
          ),
          textAlign: TextAlign.center,
          style: theme.textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
            height: 1.1,
          ),
        ),
        const SizedBox(height: KioskTokens.spaceS),
        Text(
          l10n.memberAttachedBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (tier != null && tier.isNotEmpty) ...[
          const SizedBox(height: KioskTokens.spaceM),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: KioskTokens.spaceM,
                vertical: KioskTokens.spaceXS,
              ),
              decoration: BoxDecoration(
                color: scheme.tertiary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.memberTierLabel(_localizedTierName(l10n, tier)),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
        if (member.benefits.isNotEmpty) ...[
          const SizedBox(height: KioskTokens.spaceL),
          Container(
            padding: const EdgeInsets.all(KioskTokens.spaceM),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(KioskTokens.radiusMedium),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final benefit in member.benefits)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: KioskTokens.spaceXS / 2,
                    ),
                    child: Builder(
                      builder: (context) {
                        final localized = _localizedBenefit(
                          l10n,
                          benefit,
                          member,
                        );
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: scheme.tertiary,
                              size: 24,
                            ),
                            const SizedBox(width: KioskTokens.spaceS),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    localized.label,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: scheme.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  if (localized.description != null &&
                                      localized.description!.isNotEmpty)
                                    Text(
                                      localized.description!,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: KioskTokens.spaceXL),
        SizedBox(
          height: KioskTokens.touchTargetLarge,
          child: FilledButton(
            onPressed: onContinue,
            style: FilledButton.styleFrom(foregroundColor: Colors.white),
            child: Text(
              l10n.memberContinue.toUpperCase(),
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView({
    required this.query,
    required this.message,
    required this.onRetry,
    required this.onSkip,
  });

  final String query;
  final String? message;
  final VoidCallback onRetry;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_off_rounded,
              size: 48,
              color: scheme.onErrorContainer,
            ),
          ),
        ),
        const SizedBox(height: KioskTokens.spaceL),
        Text(
          l10n.memberNotFoundTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: KioskTokens.spaceM),
        Text(
          message ?? l10n.memberNotFoundBody(query),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: KioskTokens.spaceXL),
        SizedBox(
          height: KioskTokens.touchTargetLarge,
          child: FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(foregroundColor: Colors.white),
            child: Text(
              l10n.memberRetry.toUpperCase(),
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: KioskTokens.spaceS),
        SizedBox(
          height: KioskTokens.touchTargetLarge,
          child: OutlinedButton(
            onPressed: onSkip,
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.primary,
              side: BorderSide(color: scheme.primary, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KioskTokens.radiusLarge),
              ),
            ),
            child: Text(
              l10n.memberSkip.toUpperCase(),
              style: theme.textTheme.titleLarge?.copyWith(
                color: scheme.primary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
