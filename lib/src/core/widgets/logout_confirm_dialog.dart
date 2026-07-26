import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Shows the "sign out" confirmation and returns `true` when the user confirms,
/// or `false`/`null` when they cancel or dismiss the dialog.
///
/// This is pure UI: the caller performs the actual sign-out based on the
/// returned value.
Future<bool> showLogoutConfirmDialog(BuildContext context) async {
  HapticFeedback.lightImpact();
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => const _LogoutConfirmDialog(),
  );
  return result ?? false;
}

class _LogoutConfirmDialog extends StatelessWidget {
  const _LogoutConfirmDialog();

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
                  Icons.logout_rounded,
                  size: 48,
                  color: scheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: KioskTokens.spaceL),
              Text(
                l10n.logoutConfirmTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: KioskTokens.spaceM),
              Text(
                l10n.logoutConfirmBody,
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
                  l10n.cancel.toUpperCase(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: KioskTokens.spaceS),
              // Destructive confirm: outlined (not solid) red so it reads as the
              // dangerous action without out-shouting the safe "cancel" primary
              // above it.
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.error,
                  side: BorderSide(color: scheme.error, width: 2),
                ),
                child: Text(
                  l10n.logoutConfirm.toUpperCase(),
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
