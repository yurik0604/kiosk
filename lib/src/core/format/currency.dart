import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// Formats monetary amounts with the currency symbol always on the **left** of
/// the value (e.g. `₪55.00`, `-₪55.00`), independent of the ambient text
/// direction.
///
/// Why not [NumberFormat.simpleCurrency] directly? In RTL locales (Hebrew) that
/// formatter places the symbol on the right and embeds Unicode directional
/// marks (RLM, U+200F) around the number. Prefixing a `-` to such a string and
/// dropping it into an LTR context produces a scrambled result like `55.00₪ -`.
///
/// This formatter instead composes the string itself: it formats the plain
/// number with a neutral (LTR) pattern — so there are no directional marks or
/// stray spaces — and prepends the symbol (and an optional leading minus). The
/// result is a clean, always-left-to-right string that renders identically in
/// LTR and RTL layouts. Render it inside [Currency.ltr] (or any LTR
/// [Directionality]) so the surrounding RTL flow can't reorder it.
class CurrencyFormat {
  CurrencyFormat._(this._symbol, this._number);

  /// Builds a formatter for the given [locale] and ISO currency [name]
  /// (e.g. `'ILS'`). The symbol is taken from the locale's currency data; the
  /// number of decimal digits follows the currency's convention.
  factory CurrencyFormat.of(String locale, {String name = 'ILS'}) {
    final currency = NumberFormat.simpleCurrency(locale: locale, name: name);
    // Neutral, mark-free number formatting (grouping + fixed decimals) so we
    // can position the symbol ourselves without RTL interference.
    final number = NumberFormat.decimalPatternDigits(
      locale: 'en',
      decimalDigits: currency.decimalDigits ?? 2,
    );
    return CurrencyFormat._(currency.currencySymbol, number);
  }

  final String _symbol;
  final NumberFormat _number;

  /// The currency symbol, e.g. `₪`.
  String get symbol => _symbol;

  /// Formats [value] as `₪1,234.50`. Negative values render as `-₪1,234.50`
  /// (minus outermost-left). Pass [signed] to force a leading `-` for a
  /// positive amount that represents a deduction (e.g. a discount line).
  String format(double value, {bool signed = false}) {
    final negative = value < 0 || (signed && value != 0);
    final body = _number.format(value.abs());
    return '${negative ? '-' : ''}$_symbol$body';
  }

  /// Splits a formatted amount into the part up to (but excluding) the decimal
  /// separator ([whole], e.g. `-₪1,234`) and the fractional part *including* the
  /// separator ([fraction], e.g. `.50`). If the currency has no decimals,
  /// [fraction] is empty. Used to align amounts on their decimal point: render
  /// [whole] right-aligned so the separators land on one vertical axis, with
  /// [fraction] in a fixed slot immediately after. See [Currency.decimalAligned].
  ({String whole, String fraction}) formatParts(
    double value, {
    bool signed = false,
  }) {
    final s = format(value, signed: signed);
    final dot = s.lastIndexOf(_number.symbols.DECIMAL_SEP);
    if (dot < 0) return (whole: s, fraction: '');
    return (whole: s.substring(0, dot), fraction: s.substring(dot));
  }
}

/// Convenience widgets/helpers for rendering currency strings so they keep
/// their left-to-right order regardless of the surrounding text direction.
class Currency {
  const Currency._();

  /// Wraps [child] in a left-to-right [Directionality] so an RTL layout cannot
  /// reorder a currency string built by [CurrencyFormat].
  static Widget ltr(Widget child) =>
      Directionality(textDirection: TextDirection.ltr, child: child);

  /// Applies tabular figures to [style] so every digit occupies the same width —
  /// a prerequisite for the trailing edges (and thus the `.00` and the currency
  /// symbol) of a stack of amounts to line up when they are right-aligned.
  static TextStyle? _tabular(TextStyle? style) => (style ?? const TextStyle())
      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// A whole currency string (e.g. `₪245.00`, `-₪55.00`) rendered LTR with
  /// tabular figures. Place it in a trailing-aligned column: the strings then
  /// share a right edge, so the fractional `.00` and the currency symbol line up
  /// vertically while the integer digits grow leftward from that edge.
  static Widget amount(String text, {required TextStyle? style}) => ltr(
    Text(text, style: _tabular(style), maxLines: 1, softWrap: false),
  );

  /// An amount rendered so its **decimal separator** lands on a fixed vertical
  /// axis: the whole part ([parts].whole, e.g. `-₪20`) is right-aligned inside a
  /// fixed-width [wholeSlot] box, and the fraction ([parts].fraction, e.g. `.00`)
  /// follows. Give every amount in a stack the same [wholeSlot] (the widest
  /// whole part's measured width) and they share one decimal axis — dot below
  /// dot — regardless of how many integer digits each has.
  ///
  /// Sizing the slots explicitly (rather than with [Expanded]) avoids the
  /// unbounded-width conflict that a flexible child would hit inside an
  /// intrinsic-width table column. Measure [wholeSlot] with [measureWidth].
  /// Build [parts] with [CurrencyFormat.formatParts].
  static Widget decimalAligned(
    ({String whole, String fraction}) parts, {
    required TextStyle? style,
    required double wholeSlot,
  }) {
    final s = _tabular(style);
    return ltr(
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: wholeSlot,
            child: Text(
              parts.whole,
              style: s,
              textAlign: TextAlign.end,
              maxLines: 1,
              softWrap: false,
            ),
          ),
          Text(parts.fraction, style: s, maxLines: 1, softWrap: false),
        ],
      ),
    );
  }

  /// Measures the rendered width of [text] in [style] with tabular figures, for
  /// sizing the [decimalAligned] whole-part slot to the widest amount.
  static double measureWidth(String text, TextStyle? style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: _tabular(style)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }
}
