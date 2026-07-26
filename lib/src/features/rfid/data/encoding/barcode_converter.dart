/// Barcode Converter Interface and Shared Types
///
/// Abstract interface for barcode encoding/decoding implementations.
/// Supports multiple encoding standards (GS1, Lululemon, XCode) selected by
/// the group's `encoding_standard` setting.
///
/// Ported from the field app so the kiosk decodes EPCs byte-for-byte the same
/// way. Kept decode-focused for the kiosk (the encode paths are retained for
/// parity but the kiosk only ever decodes reads).
library;

import 'dart:math';

import '../../../group/domain/group_settings.dart' show EncodingStandard;
import 'gs1_converter.dart';
import 'lululemon_converter.dart';
import 'xcode_converter.dart';

/// Enumeration for supported barcode formats
enum BarcodeFormat {
  upc12,
  ean13,
  ean14,
  gtin14,
}

/// Enumeration for EPC filter values (GS1 EPC SGTIN-96 spec).
///
/// Values 3 and 5 are reserved by GS1 for future use.
enum EpcFilter {
  allOthers(0, 'All Others'),
  pointOfSale(1, 'Point of Sale'),
  fullCase(2, 'Full Case'),
  reserved3(3, 'Reserved 3'),
  innerPack(4, 'Inner Pack'),
  reserved5(5, 'Reserved 5'),
  unitLoad(6, 'Unit Load'),
  component(7, 'Component');

  const EpcFilter(this.value, this.displayName);
  final int value;
  final String displayName;

  /// Human-readable label including the numeric value, e.g. "Inner Pack (4)".
  String get displayNameWithValue => '$displayName ($value)';
}

/// Data class representing decoded barcode information
class BarcodeData {
  final String gtin;
  final String companyPrefix;
  final String itemReference;
  final String serialNumber;
  final BarcodeFormat format;
  final EpcFilter filter;
  final bool isValid;

  /// Optional override for the encoding standard that decoded this EPC.
  /// When set, this takes precedence over the factory's current standard.
  /// Used when a fallback decoder (e.g. RCode inside XCode) successfully
  /// decodes the EPC.
  final String? decodedByStandard;

  const BarcodeData({
    required this.gtin,
    required this.companyPrefix,
    required this.itemReference,
    required this.serialNumber,
    required this.format,
    required this.filter,
    required this.isValid,
    this.decodedByStandard,
  });

  @override
  String toString() {
    return 'BarcodeData(gtin: $gtin, companyPrefix: $companyPrefix, '
        'itemReference: $itemReference, serialNumber: $serialNumber, '
        'format: $format, filter: $filter, isValid: $isValid'
        '${decodedByStandard != null ? ', decodedBy: $decodedByStandard' : ''})';
  }

  Map<String, dynamic> toJson() {
    return {
      'gtin': gtin,
      'companyPrefix': companyPrefix,
      'itemReference': itemReference,
      'serialNumber': serialNumber,
      'format': format.name,
      'filter': filter.name,
      'isValid': isValid,
      if (decodedByStandard != null) 'decodedByStandard': decodedByStandard,
    };
  }
}

/// Data class representing company prefix information
class CompanyPrefixData {
  final String prefix;
  final int length;
  final int partitionValue;
  final int companyPrefixBits;
  final int itemReferenceBits;

  const CompanyPrefixData({
    required this.prefix,
    required this.length,
    required this.partitionValue,
    required this.companyPrefixBits,
    required this.itemReferenceBits,
  });

  @override
  String toString() {
    return 'CompanyPrefixData(prefix: $prefix, length: $length, '
        'partitionValue: $partitionValue, companyPrefixBits: $companyPrefixBits, '
        'itemReferenceBits: $itemReferenceBits)';
  }

  Map<String, dynamic> toJson() {
    return {
      'prefix': prefix,
      'length': length,
      'partitionValue': partitionValue,
      'companyPrefixBits': companyPrefixBits,
      'itemReferenceBits': itemReferenceBits,
    };
  }
}

/// Exception thrown when barcode/EPC operations fail
class BarcodeException implements Exception {
  final String message;
  final String? code;

  const BarcodeException(this.message, [this.code]);

  @override
  String toString() =>
      'BarcodeException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Abstract interface for barcode converter implementations
abstract class BarcodeConverter {
  /// Decode EPC hex string to barcode data
  BarcodeData decodeFromEpc(String epcHex);

  /// Encode barcode to EPC hex string
  String encodeToEpc({
    required String barcode,
    required int serialNumber,
    required int companyPrefixLength,
    EpcFilter filterValue = EpcFilter.pointOfSale,
    bool skipCheckDigitValidation = false,
    int? customerXcodePrefix,
  });

  /// Calculate check digit for barcode
  String calculateCheckDigit(String partialBarcode);

  /// Validate barcode format and check digit
  bool validateBarcode(String barcode);

  /// Normalize barcode to standard format (e.g., GTIN-14 for GS1)
  String normalizeToGtin14(String barcode, {bool skipCheckDigitValidation = false});

  /// Determine barcode format from string
  BarcodeFormat getBarcodeFormat(String barcode);

  /// Extract company prefix information
  CompanyPrefixData extractCompanyPrefix(String gtin14, int companyPrefixLength);

  /// Extract company prefix string from barcode with validation.
  ///
  /// Returns the prefix string or null if extraction fails. Normalizes the
  /// barcode to GTIN-14, extracts the prefix at the specified length, and
  /// validates the result.
  String? extractPrefixFromBarcode(String barcode, int prefixLength,
      {bool skipCheckDigitValidation = false});

  /// Generate a random serial number appropriate for this encoding standard.
  /// Each converter knows its own serial number constraints; override in
  /// subclasses that have different serial limits.
  int generateSerial({String? barcode}) {
    // Default: conservative limit compatible with GS1 SGTIN-96
    const defaultLimit = 131072;
    return Random().nextInt(defaultLimit);
  }
}

/// Factory class for creating barcode converters based on encoding standard.
///
/// The current standard is set from the group's settings (see
/// `TagProcessingCoordinator`) and MUST be initialized before any decode.
class BarcodeConverterFactory {
  // Private constructor to prevent instantiation
  BarcodeConverterFactory._();

  // Cache converters to reuse instances
  static final Map<EncodingStandard, BarcodeConverter> _converters = {};

  // Static reference to current encoding standard - NO DEFAULT VALUE.
  // Must be explicitly set from group configuration.
  static EncodingStandard? _currentStandard;

  /// Set the current encoding standard used by the factory.
  /// This MUST be called with the value from the group's settings.
  static void setCurrentStandard(EncodingStandard standard) {
    _currentStandard = standard;
  }

  /// Get the current encoding standard.
  /// Throws if not initialized from group settings.
  static EncodingStandard getCurrentStandard() {
    if (_currentStandard == null) {
      throw StateError(
        'BarcodeConverterFactory not initialized. '
        'Encoding standard must be set from group settings before use.',
      );
    }
    return _currentStandard!;
  }

  /// Get the appropriate barcode converter based on the current encoding
  /// standard. The encoding standard MUST be set from group configuration first.
  static BarcodeConverter getConverter() {
    if (_currentStandard == null) {
      throw StateError(
        'BarcodeConverterFactory not initialized. '
        'Encoding standard must be set from group settings before use.',
      );
    }

    final standard = _currentStandard!;

    // Return cached instance if available
    if (_converters.containsKey(standard)) {
      return _converters[standard]!;
    }

    // Create new instance based on standard
    final BarcodeConverter converter;
    switch (standard) {
      case EncodingStandard.gs1:
        converter = Gs1Converter();
        break;
      case EncodingStandard.lululemon:
        converter = LululemonConverter();
        break;
      case EncodingStandard.xcode:
        converter = XCodeConverter();
        break;
    }

    // Cache the converter instance
    _converters[standard] = converter;
    return converter;
  }

  /// Clear cached converters (useful for testing).
  static void clearCache() {
    _converters.clear();
  }
}
