/// EAN-13 barcode helpers.
///
/// Real products carry a manufacturer-assigned EAN-13. In this demo seed we
/// don't have one, so we derive a deterministic 12-digit base from the SKU
/// and append the standard EAN-13 check digit.
library;

class Ean13 {
  Ean13._(this.digits);

  final String digits;

  static Ean13 fromSku(String sku) {
    final base12 = _deterministic12Digits(sku);
    final check = _checkDigit(base12);
    return Ean13._('$base12$check');
  }

  String get formatted => digits;

  static String _deterministic12Digits(String input) {
    // Stable, non-cryptographic hash (FNV-1a 64-bit) → 12 decimal digits.
    var hash = BigInt.parse('14695981039346656037'); // FNV offset basis
    final prime = BigInt.parse('1099511628211'); // FNV prime
    final mask = (BigInt.one << 64) - BigInt.one;
    final bytes = input.codeUnits;
    for (final b in bytes) {
      hash = (hash ^ BigInt.from(b)) * prime;
      hash = hash & mask;
    }
    final str = hash.toString();
    if (str.length >= 12) return str.substring(0, 12);
    return str.padLeft(12, '0');
  }

  static int _checkDigit(String base12) {
    var sum = 0;
    for (var i = 0; i < base12.length; i++) {
      final d = base12.codeUnitAt(i) - 0x30;
      sum += (i.isEven) ? d : d * 3;
    }
    return (10 - (sum % 10)) % 10;
  }
}
