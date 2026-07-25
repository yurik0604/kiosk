import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import 'numeric_keypad.dart';

/// Prompts the shopper to enter a phone number on the shared [NumericKeypad],
/// returning the entered digits, or `null` if they cancelled / dismissed.
///
/// Used by the receipt flow when SMS delivery is chosen but no phone was
/// captured earlier. The caller is responsible for persisting the result (e.g.
/// into the current-shopper provider).
Future<String?> showPhoneEntryDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black54,
    barrierDismissible: false,
    builder: (_) => const _PhoneEntryDialog(),
  );
}

class _PhoneEntryDialog extends StatefulWidget {
  const _PhoneEntryDialog();

  @override
  State<_PhoneEntryDialog> createState() => _PhoneEntryDialogState();
}

class _PhoneEntryDialogState extends State<_PhoneEntryDialog> {
  final KeypadInput _input = KeypadInput();

  @override
  void initState() {
    super.initState();
    _input.addListener(_onChanged);
  }

  @override
  void dispose() {
    _input.removeListener(_onChanged);
    _input.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _isValid => _input.value.length >= 7;

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
                    Icons.smartphone_rounded,
                    size: 48,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: KioskTokens.spaceL),
              Text(
                l10n.phoneEntryTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: KioskTokens.spaceS),
              Text(
                l10n.phoneEntrySubtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: KioskTokens.spaceL),
              KeypadDisplay(
                input: _input.value,
                placeholder: l10n.phoneEntryPlaceholder,
              ),
              const SizedBox(height: KioskTokens.spaceL),
              NumericKeypad(
                onDigit: _input.append,
                onBackspace: _input.backspace,
                onClear: _input.clear,
                canClear: _input.isNotEmpty,
              ),
              const SizedBox(height: KioskTokens.spaceL),
              SizedBox(
                height: KioskTokens.touchTargetLarge,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
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
                        onPressed: _isValid
                            ? () =>
                                  Navigator.of(context).pop(_input.value.trim())
                            : null,
                        style: FilledButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: Text(l10n.phoneEntrySend.toUpperCase()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
