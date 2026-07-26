import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/data/auth_controller.dart';
import '../data/kiosk_controller.dart';
import '../data/kiosk_service.dart';

/// Shown when the device's kiosk can't be resolved after login. The kiosk model
/// is essential to kiosk functionality, so the home screen is blocked until a
/// kiosk is available.
///
/// The message adapts to the failure:
/// - a genuine "not defined" (HTTP 404) → contact-IT copy;
/// - a transient failure (network / 5xx) → can't-reach-server copy.
///
/// The only action is **Close**, which signs the user out and returns to the
/// login screen.
class KioskNotDefinedScreen extends ConsumerWidget {
  const KioskNotDefinedScreen({super.key});

  Future<void> _close(BuildContext context, WidgetRef ref) async {
    // Sign out; the router redirect (gating on auth) then routes back to login.
    // No manual navigation needed — clearing auth is enough.
    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    // Pick the message from the failure reason:
    //  - 404       → the kiosk isn't available for this user (contact IT);
    //  - server    → server responded with an error (reachable, contact IT);
    //  - network   → the server couldn't be reached (check the network).
    final reason = ref.watch(
      kioskControllerProvider.select((s) => s.failureReason),
    );
    final String title;
    final String body;
    switch (reason) {
      case KioskFailureReason.notDefined:
        title = l10n.kioskNotDefinedTitle;
        body = l10n.kioskNotDefinedBody;
      case KioskFailureReason.network:
        title = l10n.kioskUnavailableTitle;
        body = l10n.kioskUnavailableBody;
      case KioskFailureReason.serverError:
      case null:
        title = l10n.kioskServerErrorTitle;
        body = l10n.kioskServerErrorBody;
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.errorContainer,
                scheme.surface,
                scheme.secondaryContainer,
              ],
              stops: const [0, 0.5, 1],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: KioskTokens.spaceL,
                  vertical: KioskTokens.spaceXL,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: BorderRadius.circular(
                            KioskTokens.radiusXLarge,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.error.withValues(alpha: 0.25),
                              blurRadius: 32,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.report_gmailerrorred_rounded,
                          size: 84,
                          color: scheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: KioskTokens.spaceL),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: KioskTokens.spaceM),
                      Text(
                        body,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                      ),
                      const SizedBox(height: KioskTokens.spaceXL),
                      SizedBox(
                        width: double.infinity,
                        height: KioskTokens.touchTargetHero,
                        child: FilledButton(
                          onPressed: () => _close(context, ref),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                KioskTokens.radiusXLarge,
                              ),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              l10n.kioskNotDefinedClose.toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    color: scheme.onPrimary,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
