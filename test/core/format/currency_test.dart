import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk/src/core/format/currency.dart';

void main() {
  group('CurrencyFormat (Hebrew/ILS)', () {
    final fmt = CurrencyFormat.of('he', name: 'ILS');

    test('places the symbol on the left of the value', () {
      expect(fmt.format(55), '₪55.00');
      expect(fmt.format(220), '₪220.00');
    });

    test('groups thousands and keeps two decimals', () {
      expect(fmt.format(1234.5), '₪1,234.50');
    });

    test('signed:true forces a leading minus for a positive deduction', () {
      expect(fmt.format(55, signed: true), '-₪55.00');
      expect(fmt.format(12.25, signed: true), '-₪12.25');
    });

    test('negative values render minus outermost-left', () {
      expect(fmt.format(-19), '-₪19.00');
    });

    test('contains no Unicode directional marks (RLM/LRM)', () {
      // U+200F RLM, U+200E LRM — these scramble ordering in RTL layouts.
      final out = fmt.format(55, signed: true);
      expect(out.codeUnits, isNot(contains(0x200F)));
      expect(out.codeUnits, isNot(contains(0x200E)));
    });

    test('zero is unsigned even with signed:true', () {
      expect(fmt.format(0, signed: true), '₪0.00');
    });

    test('all amounts end in the same ".00" so trailing edges align', () {
      // The card price column is trailing-aligned; when every amount shares the
      // same trailing ".NN" the decimals and the ₪ stack vertically.
      final tails = [245.0, 220.0, 165.0, 45.0]
          .map((v) => fmt.format(v).substring(fmt.format(v).length - 3))
          .toSet();
      expect(tails, {'.00'});
    });

    group('formatParts (decimal-point alignment)', () {
      test('whole excludes the separator, fraction includes it', () {
        expect(fmt.formatParts(65), (whole: '₪65', fraction: '.00'));
        expect(
          fmt.formatParts(20, signed: true),
          (whole: '-₪20', fraction: '.00'),
        );
      });

      test('grouping stays in the whole part', () {
        expect(fmt.formatParts(1234.5), (whole: '₪1,234', fraction: '.50'));
      });

      test('every fraction is the same ".00" so dots align across amounts', () {
        final fractions = [65.0, 20.0, 189.0, 9.45]
            .map((v) => fmt.formatParts(v).fraction)
            .toSet();
        // 9.45 differs; the point is the separator position is consistent.
        expect(fractions.every((f) => f.startsWith('.')), isTrue);
        expect(fmt.formatParts(65).fraction, '.00');
        expect(fmt.formatParts(20).fraction, '.00');
      });

      test('reassembling whole + fraction reproduces format()', () {
        for (final v in [65.0, 20.0, 189.0, 45.0, 1234.5]) {
          final p = fmt.formatParts(v);
          expect('${p.whole}${p.fraction}', fmt.format(v));
        }
      });
    });
  });
}
