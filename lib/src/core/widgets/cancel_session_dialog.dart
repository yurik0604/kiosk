import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Shows the "cancel session" confirmation and returns `true` when the user
/// confirms the cancellation, or `false`/`null` when they choose to keep
/// shopping or dismiss the dialog.
///
/// This is the single, reusable cancel-confirmation used across the session and
/// checkout screens. It is pure UI: the caller performs the actual reset and
/// navigation based on the returned value.
///
/// The copy defaults to the shared session-cancel strings; pass [title], [body],
/// [confirmLabel], or [keepLabel] to override for a specific screen.
Future<bool> showCancelSessionDialog(
  BuildContext context, {
  String? title,
  String? body,
  String? confirmLabel,
  String? keepLabel,
}) async {
  HapticFeedback.lightImpact();
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _CancelSessionDialog(
      title: title,
      body: body,
      confirmLabel: confirmLabel,
      keepLabel: keepLabel,
    ),
  );
  return result ?? false;
}

class _CancelSessionDialog extends StatelessWidget {
  const _CancelSessionDialog({
    this.title,
    this.body,
    this.confirmLabel,
    this.keepLabel,
  });

  final String? title;
  final String? body;
  final String? confirmLabel;
  final String? keepLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: KioskTokens.spaceXL),
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
                title ?? l10n.cancelSessionTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: KioskTokens.spaceM),
              Text(
                body ?? l10n.cancelSessionBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: KioskTokens.spaceXL),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: FilledButton.styleFrom(foregroundColor: Colors.white),
                child: Text(
                  (keepLabel ?? l10n.keepShopping).toUpperCase(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: KioskTokens.spaceS),
              // Destructive confirm: outlined (not solid) red so it reads as the
              // dangerous action without out-shouting the safe "keep shopping"
              // primary above it.
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.error,
                  side: BorderSide(color: scheme.error, width: 2),
                ),
                child: Text(
                  (confirmLabel ?? l10n.cancelSession).toUpperCase(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: scheme.error,
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
  }
}
