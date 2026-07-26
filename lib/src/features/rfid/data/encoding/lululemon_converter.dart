/// Lululemon Barcode Converter
/// Implementation for Lululemon-specific EPC encoding/decoding.
/// Based on Lululemon EPC Converter v4.3 specifications.
library;

import 'dart:math';

import 'barcode_converter.dart';

/// Data class for Lululemon-specific decoded data
class LululemonData {
  final String hexEpc;
  final String tvEpc;
  final String sgtin;
  final BigInt sku;
  final BigInt serialNumber;
  final bool isBlankTag;

  const LululemonData({
    required this.hexEpc,
    required this.tvEpc,
    required this.sgtin,
    required this.sku,
    required this.serialNumber,
    this.isBlankTag = false,
  });

  @override
  String toString() {
    return 'LululemonData(hexEpc: $hexEpc, tvEpc: $tvEpc, sgtin: $sgtin, '
        'sku: $sku, serialNumber: $serialNumber, isBlankTag: $isBlankTag)';
  }

  Map<String, dynamic> toJson() {
    return {
      'hexEpc': hexEpc,
      'tvEpc': tvEpc,
      'sgtin': sgtin,
      'sku': sku.toString(),
      'serialNumber': serialNumber.toString(),
      'isBlankTag': isBlankTag,
    };
  }
}

/// Lululemon-specific implementation of barcode converter.
/// Implements the encoding scheme from Lululemon EPC Converter v4.3.
///
/// EPC Structure (96-bit):
/// - Header: 12 bits (0x3BD for normal tags, 0x3BF for blank tags)
/// - SKU: 50 bits
/// - Serial Number: 34 bits
class LululemonConverter implements BarcodeConverter {
  // Lululemon EPC header (binary: 001110111101)
  static const String _normalTagHeader = '3BD';
  static const String _blankTagHeader = '3BF';
  static const String _headerBinary = '001110111101';

  // Bit lengths for EPC components
  static const int _headerBits = 12;
  static const int _skuBits = 50;
  static const int _serialBits = 34;
  static const int _totalBits = 96;

  // Max lengths for SKU and Serial
  static const int _maxSkuLength = 15;
  static const int _maxSerialLength = 11;

  /// Convert EPC from various formats to all Lululemon formats.
  /// Supports HEX EPC, TV EPC, and SGTIN input formats.
  LululemonData convertToAllFormats(String value) {
    String hexEpc;
    String tvEpc;
    String sgtin;
    BigInt sku;
    BigInt serialNumber;
    bool isBlankTag = false;

    final trimmedValue = value.trim();

    if (trimmedValue.contains('vue:tag')) {
      // TV EPC format: urn:vue:tag:ser-96:{SKU}.{Serial}
      final skuSerial = _extractSkuAndSerialFromTvEpc(trimmedValue);
      sku = skuSerial.$1;
      serialNumber = skuSerial.$2;
      hexEpc = _convertToHexEpc(sku, serialNumber);
      tvEpc = trimmedValue;
      sgtin = _getSgtin(sku, serialNumber);
    } else if (trimmedValue.contains('epc:id')) {
      // SGTIN format: urn:epc:id:sgtin:2{prefix}.0{last5}.{serial}
      final skuSerial = _extractSkuAndSerialFromSgtin(trimmedValue);
      sku = skuSerial.$1;
      serialNumber = skuSerial.$2;
      hexEpc = _convertToHexEpc(sku, serialNumber);
      tvEpc = _getTvEpc(sku, serialNumber);
      sgtin = trimmedValue;
    } else if (trimmedValue.toUpperCase().contains(_normalTagHeader) ||
        trimmedValue.toUpperCase().contains(_blankTagHeader)) {
      // HEX EPC format
      if (trimmedValue.toUpperCase().contains(_blankTagHeader)) {
        isBlankTag = true;
      }
      hexEpc = trimmedValue.toUpperCase();
      final skuSerial = _convertFromHexEpc(hexEpc);
      sku = skuSerial.$1;
      serialNumber = skuSerial.$2;
      tvEpc = _getTvEpc(sku, serialNumber);
      sgtin = _getSgtin(sku, serialNumber);
    } else {
      throw BarcodeException(
        'Invalid Lululemon EPC format: $value. '
        'Expected HEX (3BD/3BF prefix), TV EPC (vue:tag), or SGTIN (epc:id) format.',
        'INVALID_FORMAT',
      );
    }

    return LululemonData(
      hexEpc: hexEpc,
      tvEpc: tvEpc,
      sgtin: sgtin,
      sku: sku,
      serialNumber: serialNumber,
      isBlankTag: isBlankTag,
    );
  }

  /// Encode SKU and Serial Number to HEX EPC
  String encodeFromSkuAndSerial(BigInt sku, BigInt serialNumber) {
    return _convertToHexEpc(sku, serialNumber);
  }

  /// Encode SKU and Serial Number (as strings) to HEX EPC
  String encodeFromSkuAndSerialStrings(String skuStr, String serialStr) {
    if (skuStr.isEmpty) {
      throw BarcodeException('SKU cannot be empty', 'EMPTY_SKU');
    }
    if (serialStr.isEmpty) {
      throw BarcodeException('Serial number cannot be empty', 'EMPTY_SERIAL');
    }
    if (skuStr.length > _maxSkuLength) {
      throw BarcodeException(
        'SKU too long: ${skuStr.length} characters (max $_maxSkuLength)',
        'SKU_TOO_LONG',
      );
    }
    if (serialStr.length > _maxSerialLength) {
      throw BarcodeException(
        'Serial number too long: ${serialStr.length} characters (max $_maxSerialLength)',
        'SERIAL_TOO_LONG',
      );
    }

    final sku = BigInt.tryParse(skuStr);
    final serialNumber = BigInt.tryParse(serialStr);

    if (sku == null) {
      throw BarcodeException('Invalid SKU: $skuStr', 'INVALID_SKU');
    }
    if (serialNumber == null) {
      throw BarcodeException('Invalid serial number: $serialStr', 'INVALID_SERIAL');
    }

    return _convertToHexEpc(sku, serialNumber);
  }

  /// Decode HEX EPC to SKU and Serial Number
  (BigInt sku, BigInt serialNumber) decodeToSkuAndSerial(String hexEpc) {
    return _convertFromHexEpc(hexEpc);
  }

  /// Check if HEX EPC is a blank tag
  bool isBlankTag(String hexEpc) {
    return hexEpc.toUpperCase().contains(_blankTagHeader);
  }

  /// Get TV EPC format string from SKU and Serial
  String getTvEpc(BigInt sku, BigInt serialNumber) {
    return _getTvEpc(sku, serialNumber);
  }

  /// Get SGTIN format string from SKU and Serial
  String getSgtin(BigInt sku, BigInt serialNumber) {
    return _getSgtin(sku, serialNumber);
  }

  // Private implementation methods

  /// Convert SKU and Serial to HEX EPC
  String _convertToHexEpc(BigInt sku, BigInt serialNumber) {
    // Convert to binary with proper padding
    final skuBinary = sku.toRadixString(2).padLeft(_skuBits, '0');
    final serialBinary = serialNumber.toRadixString(2).padLeft(_serialBits, '0');

    // Validate bit lengths
    if (skuBinary.length > _skuBits) {
      throw BarcodeException(
        'SKU value too large: requires ${skuBinary.length} bits (max $_skuBits)',
        'SKU_OVERFLOW',
      );
    }
    if (serialBinary.length > _serialBits) {
      throw BarcodeException(
        'Serial number too large: requires ${serialBinary.length} bits (max $_serialBits)',
        'SERIAL_OVERFLOW',
      );
    }

    // Combine header + SKU + Serial
    final binaryString = _headerBinary + skuBinary + serialBinary;

    // Convert binary to hex
    return _binaryToHex(binaryString);
  }

  /// Convert HEX EPC to SKU and Serial
  (BigInt sku, BigInt serialNumber) _convertFromHexEpc(String hexEpc) {
    // Convert hex to binary
    final binary = _hexToBinary(hexEpc);

    // Extract SKU and Serial from binary.
    // Skip first 12 bits (header)
    final skuBinary = binary.substring(_headerBits, _headerBits + _skuBits);
    final serialBinary = binary.substring(_headerBits + _skuBits, _totalBits);

    // Convert binary to BigInt
    final sku = BigInt.parse(skuBinary, radix: 2);
    final serialNumber = BigInt.parse(serialBinary, radix: 2);

    return (sku, serialNumber);
  }

  /// Generate TV EPC format string
  String _getTvEpc(BigInt sku, BigInt serialNumber) {
    return 'urn:vue:tag:ser-96:$sku.$serialNumber';
  }

  /// Generate SGTIN format string
  String _getSgtin(BigInt sku, BigInt serialNumber) {
    final skuStr = sku.toString();

    // Extract the last 5 digits of SKU
    final last5Digits = skuStr.length >= 5
        ? '0${skuStr.substring(skuStr.length - 5)}'
        : '0${skuStr.padLeft(5, '0')}';

    // Pad the remaining digits with zeros to make it 6 characters long
    final remainingDigits = skuStr.length > 5
        ? skuStr.substring(0, skuStr.length - 5)
        : '';
    final paddedRemainingDigits = remainingDigits.padLeft(6, '0');

    // Combine with prefix '2'
    return 'urn:epc:id:sgtin:2$paddedRemainingDigits.$last5Digits.$serialNumber';
  }

  /// Extract SKU and Serial from TV EPC format
  (BigInt sku, BigInt serialNumber) _extractSkuAndSerialFromTvEpc(String tvEpc) {
    // Match pattern: urn:vue:tag:ser-96:{SKU}.{Serial}
    final regex = RegExp(r'(\d+)(?:\.(\d+))?$');
    final match = regex.firstMatch(tvEpc);

    if (match == null) {
      throw BarcodeException(
        'Invalid TV EPC format: $tvEpc',
        'INVALID_TV_EPC',
      );
    }

    final skuStr = match.group(1) ?? '';
    final serialStr = match.group(2) ?? '';

    if (skuStr.isEmpty) {
      throw BarcodeException(
        'Could not extract SKU from TV EPC: $tvEpc',
        'MISSING_SKU',
      );
    }

    final sku = BigInt.parse(skuStr);
    final serialNumber = serialStr.isNotEmpty ? BigInt.parse(serialStr) : BigInt.zero;

    return (sku, serialNumber);
  }

  /// Extract SKU and Serial from SGTIN format
  (BigInt sku, BigInt serialNumber) _extractSkuAndSerialFromSgtin(String sgtin) {
    // Split by dots: urn:epc:id:sgtin:2{prefix}.0{last5}.{serial}
    final parts = sgtin.split('.');

    if (parts.length < 3) {
      throw BarcodeException(
        'Invalid SGTIN format: $sgtin',
        'INVALID_SGTIN',
      );
    }

    // Extract prefix part (remove the '2' prefix from first part).
    // The first part is like "urn:epc:id:sgtin:2000035"
    final firstPart = parts[0];
    final prefixMatch = RegExp(r':2(\d+)$').firstMatch(firstPart);

    if (prefixMatch == null) {
      throw BarcodeException(
        'Could not extract prefix from SGTIN: $sgtin',
        'MISSING_PREFIX',
      );
    }

    final skuPart = prefixMatch.group(1)!; // The digits after '2'

    // Extract last 5 digits from second part (remove leading '0')
    final last5Part = parts[1];
    final last5Digits = last5Part.startsWith('0')
        ? last5Part.substring(1)
        : last5Part;

    // Combine to get full SKU.
    // The skuPart contains the first digits, last5Digits contains the last 5.
    final fullSkuStr = skuPart.replaceFirst(RegExp(r'^0+'), '') + last5Digits;
    final sku = BigInt.parse(fullSkuStr.isEmpty ? '0' : fullSkuStr);

    // Extract serial number from third part
    final serialNumber = BigInt.parse(parts[2]);

    return (sku, serialNumber);
  }

  /// Convert hex string to 96-bit binary string
  String _hexToBinary(String hex) {
    final bigInt = BigInt.parse(hex, radix: 16);
    var binary = bigInt.toRadixString(2);

    // Ensure exactly 96 bits
    if (binary.length > _totalBits) {
      binary = binary.substring(binary.length - _totalBits);
    } else {
      binary = binary.padLeft(_totalBits, '0');
    }

    return binary;
  }

  /// Convert binary string to hex string
  String _binaryToHex(String binary) {
    // Pad to multiple of 4 for hex conversion
    var paddedBinary = binary;
    while (paddedBinary.length % 4 != 0) {
      paddedBinary = '0$paddedBinary';
    }

    final buffer = StringBuffer();
    for (var i = 0; i < paddedBinary.length; i += 4) {
      final group = paddedBinary.substring(i, i + 4);
      final digit = int.parse(group, radix: 2).toRadixString(16);
      buffer.write(digit);
    }

    return buffer.toString().toUpperCase();
  }

  // BarcodeConverter interface implementation

  @override
  BarcodeData decodeFromEpc(String epcHex) {
    final data = convertToAllFormats(epcHex);

    return BarcodeData(
      gtin: data.sku.toString(),
      companyPrefix: '', // Lululemon doesn't use GS1 company prefix
      itemReference: data.sku.toString(),
      serialNumber: data.serialNumber.toString(),
      format: BarcodeFormat.gtin14, // Using as placeholder
      filter: EpcFilter.allOthers,
      isValid: true,
    );
  }

  @override
  String encodeToEpc({
    required String barcode,
    required int serialNumber,
    required int companyPrefixLength,
    EpcFilter filterValue = EpcFilter.pointOfSale,
    bool skipCheckDigitValidation = false,
    int? customerXcodePrefix,
  }) {
    // For Lululemon, barcode is treated as SKU
    final sku = BigInt.tryParse(barcode);
    if (sku == null) {
      throw BarcodeException('Invalid SKU/barcode: $barcode', 'INVALID_SKU');
    }

    return _convertToHexEpc(sku, BigInt.from(serialNumber));
  }

  @override
  String calculateCheckDigit(String partialBarcode) {
    // Lululemon uses SKU/Serial format, not traditional barcode check digits.
    // Return empty as this isn't applicable to Lululemon format.
    return '';
  }

  @override
  bool validateBarcode(String barcode) {
    // Validate that the input can be parsed as a number.
    // For Lululemon, the "barcode" is essentially a SKU.
    try {
      if (barcode.isEmpty) return false;

      // Check if it's a valid number
      final value = BigInt.tryParse(barcode);
      if (value == null) return false;

      // Check length constraints
      if (barcode.length > _maxSkuLength) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  String normalizeToGtin14(String barcode, {bool skipCheckDigitValidation = false}) {
    // For Lululemon, just ensure it's a valid SKU format.
    // Pad to reasonable length if needed.
    final cleanBarcode = barcode.replaceAll(RegExp(r'\D'), '');
    return cleanBarcode.padLeft(14, '0');
  }

  @override
  BarcodeFormat getBarcodeFormat(String barcode) {
    // Lululemon uses its own format, return GTIN-14 as closest match
    return BarcodeFormat.gtin14;
  }

  @override
  CompanyPrefixData extractCompanyPrefix(String gtin14, int companyPrefixLength) {
    // Lululemon doesn't use GS1 company prefix structure.
    // Return a placeholder with the SKU value.
    return CompanyPrefixData(
      prefix: gtin14,
      length: gtin14.length,
      partitionValue: 0,
      companyPrefixBits: 0,
      itemReferenceBits: _skuBits,
    );
  }

  @override
  String? extractPrefixFromBarcode(String barcode, int prefixLength, {bool skipCheckDigitValidation = false}) {
    // Lululemon doesn't use prefix-based structure.
    return null;
  }

  @override
  int generateSerial({String? barcode}) {
    // Lululemon supports 34-bit serial
    final random = Random();
    final high = random.nextInt(1 << 2); // 2 bits
    final low = random.nextInt(1 << 32); // 32 bits
    return (high << 32) | low;
  }
}
