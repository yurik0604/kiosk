import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// A large, LTR, digit-only keypad for kiosk numeric entry (member number,
/// phone number, etc.). Stateless and callback-driven — the parent owns the
/// accumulated input string. Reused by the member lookup and phone-entry
/// dialogs so both share one keypad implementation.
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
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
      // Digits stay left-to-right even in RTL locales.
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

/// The value display that sits above a [NumericKeypad]: a forced-LTR box with
/// tabular figures, showing [input] or a dimmed [placeholder] when empty.
class KeypadDisplay extends StatelessWidget {
  const KeypadDisplay({
    super.key,
    required this.input,
    required this.placeholder,
  });

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

/// A stateful controller mixin-free helper: accumulates a digit string with a
/// max length, firing haptics. Kept small and local so both keypad hosts can
/// reuse the same accumulation semantics.
class KeypadInput extends ChangeNotifier {
  KeypadInput({this.maxLength = 16});

  final int maxLength;
  String _value = '';

  String get value => _value;
  bool get isNotEmpty => _value.isNotEmpty;

  void append(String digit) {
    if (_value.length >= maxLength) return;
    HapticFeedback.selectionClick();
    _value = '$_value$digit';
    notifyListeners();
  }

  void backspace() {
    if (_value.isEmpty) return;
    HapticFeedback.selectionClick();
    _value = _value.substring(0, _value.length - 1);
    notifyListeners();
  }

  void clear() {
    if (_value.isEmpty) return;
    HapticFeedback.selectionClick();
    _value = '';
    notifyListeners();
  }
}
