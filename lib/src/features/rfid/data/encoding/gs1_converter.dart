/// GS1 SGTIN-96 Barcode Converter
/// Implementation for encoding and decoding between GS1 barcodes and EPC
/// (Electronic Product Code). Supports UPC-12, EAN-13, EAN-14 formats with
/// SGTIN-96 encoding.
library;

import 'dart:math';

import 'barcode_converter.dart';

/// SGTIN-96 Partition table entry
class _PartitionTableEntry {
  final int companyPrefixLength;
  final int partitionValue;
  final int companyPrefixBits;
  final int itemReferenceBits;

  const _PartitionTableEntry({
    required this.companyPrefixLength,
    required this.partitionValue,
    required this.companyPrefixBits,
    required this.itemReferenceBits,
  });
}

/// GS1 implementation of barcode converter for SGTIN-96 encoding
class Gs1Converter implements BarcodeConverter {
  /// SGTIN-96 Binary Header (8 bits) - "00110000" in binary = 0x30 in hex
  static const int _sgtinHeader = 0x30;

  /// SGTIN-96 Partition table mapping company prefix lengths to bit allocations
  /// Based on GS1 EPC Tag Data Standard
  static const List<_PartitionTableEntry> _partitionTable = [
    _PartitionTableEntry(companyPrefixLength: 12, partitionValue: 0, companyPrefixBits: 40, itemReferenceBits: 4),
    _PartitionTableEntry(companyPrefixLength: 11, partitionValue: 1, companyPrefixBits: 37, itemReferenceBits: 7),
    _PartitionTableEntry(companyPrefixLength: 10, partitionValue: 2, companyPrefixBits: 34, itemReferenceBits: 10),
    _PartitionTableEntry(companyPrefixLength: 9, partitionValue: 3, companyPrefixBits: 30, itemReferenceBits: 14),
    _PartitionTableEntry(companyPrefixLength: 8, partitionValue: 4, companyPrefixBits: 27, itemReferenceBits: 17),
    _PartitionTableEntry(companyPrefixLength: 7, partitionValue: 5, companyPrefixBits: 24, itemReferenceBits: 20),
    _PartitionTableEntry(companyPrefixLength: 6, partitionValue: 6, companyPrefixBits: 20, itemReferenceBits: 24),
  ];

  /// Maximum serial number that can be encoded in SGTIN-96 (38 bits)
  static const int maxSerialNumber = 0x3FFFFFFFFF; // 2^38 - 1

  /// Lookup partition table entry by company prefix length
  _PartitionTableEntry? _getPartitionEntry(int companyPrefixLength) {
    try {
      return _partitionTable.firstWhere((entry) => entry.companyPrefixLength == companyPrefixLength);
    } catch (e) {
      return null;
    }
  }

  /// Lookup partition table entry by partition value
  _PartitionTableEntry? _getPartitionEntryByValue(int partitionValue) {
    try {
      return _partitionTable.firstWhere((entry) => entry.partitionValue == partitionValue);
    } catch (e) {
      return null;
    }
  }

  @override
  String calculateCheckDigit(String partialBarcode) {
    if (partialBarcode.isEmpty) {
      throw const BarcodeException('Partial barcode cannot be empty', 'EMPTY_INPUT');
    }

    // Remove any existing check digit and ensure we have only digits
    final cleanCode = partialBarcode.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCode.length < 2) {
      throw const BarcodeException('Partial barcode must have at least 2 digits', 'INVALID_LENGTH');
    }

    int sum = 0;
    bool isOddPosition = true;

    // Process digits from right to left
    for (int i = cleanCode.length - 1; i >= 0; i--) {
      final digit = int.parse(cleanCode[i]);

      if (isOddPosition) {
        sum += digit * 3; // Multiply odd positions (from right) by 3
      } else {
        sum += digit; // Add even positions (from right) as is
      }

      isOddPosition = !isOddPosition;
    }

    // Calculate check digit: (10 - (sum mod 10)) mod 10
    final checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit.toString();
  }

  @override
  bool validateBarcode(String barcode) {
    if (barcode.isEmpty) return false;

    // Remove any non-digit characters
    final cleanBarcode = barcode.replaceAll(RegExp(r'[^0-9]'), '');

    // Check valid lengths for supported formats
    if (![8, 12, 13, 14].contains(cleanBarcode.length)) {
      return false;
    }

    // Validate check digit
    final partialBarcode = cleanBarcode.substring(0, cleanBarcode.length - 1);
    final providedCheckDigit = cleanBarcode.substring(cleanBarcode.length - 1);
    final calculatedCheckDigit = calculateCheckDigit(partialBarcode);

    return providedCheckDigit == calculatedCheckDigit;
  }

  @override
  String normalizeToGtin14(String barcode, {bool skipCheckDigitValidation = false}) {
    if (barcode.isEmpty) {
      throw const BarcodeException('Barcode cannot be empty', 'EMPTY_INPUT');
    }

    // Remove any non-digit characters
    final cleanBarcode = barcode.replaceAll(RegExp(r'[^0-9]'), '');

    // Validate input length (unless explicitly skipped)
    if (!skipCheckDigitValidation && ![8, 12, 13, 14].contains(cleanBarcode.length)) {
      throw BarcodeException('Invalid barcode length: ${cleanBarcode.length}. Expected 8, 12, 13, or 14 digits', 'INVALID_LENGTH');
    }

    // Validate check digit (unless explicitly skipped)
    if (!skipCheckDigitValidation && !validateBarcode(cleanBarcode)) {
      throw const BarcodeException('Invalid check digit', 'INVALID_CHECK_DIGIT');
    }

    // Pad with leading zeros to make it 14 digits
    return cleanBarcode.padLeft(14, '0');
  }

  @override
  BarcodeFormat getBarcodeFormat(String barcode) {
    final cleanBarcode = barcode.replaceAll(RegExp(r'[^0-9]'), '');

    switch (cleanBarcode.length) {
      case 8:
        return BarcodeFormat.ean13; // EAN-8 is treated as EAN-13 family
      case 12:
        return BarcodeFormat.upc12;
      case 13:
        return BarcodeFormat.ean13;
      case 14:
        return BarcodeFormat.ean14;
      default:
        throw BarcodeException('Unsupported barcode length: ${cleanBarcode.length}', 'UNSUPPORTED_FORMAT');
    }
  }

  @override
  CompanyPrefixData extractCompanyPrefix(String gtin14, int companyPrefixLength) {
    if (gtin14.length != 14) {
      throw const BarcodeException('GTIN must be 14 digits', 'INVALID_GTIN_LENGTH');
    }

    if (companyPrefixLength < 6 || companyPrefixLength > 12) {
      throw const BarcodeException('Company prefix length must be between 6 and 12 digits', 'INVALID_PREFIX_LENGTH');
    }

    final partitionEntry = _getPartitionEntry(companyPrefixLength);
    if (partitionEntry == null) {
      throw BarcodeException('Unsupported company prefix length: $companyPrefixLength', 'UNSUPPORTED_PREFIX_LENGTH');
    }

    // Extract company prefix (skip indicator digit at position 0)
    final companyPrefix = gtin14.substring(1, 1 + companyPrefixLength);

    // Extract item reference (remaining digits before check digit)
    final itemReference = gtin14.substring(1 + companyPrefixLength, 13);

    // Validate item reference fits in allocated bits
    final maxItemReference = (1 << partitionEntry.itemReferenceBits) - 1;
    final itemReferenceValue = int.parse(itemReference);

    if (itemReferenceValue > maxItemReference) {
      throw BarcodeException('Item reference $itemReference exceeds maximum value for $companyPrefixLength-digit company prefix', 'ITEM_REFERENCE_OVERFLOW');
    }

    return CompanyPrefixData(
      prefix: companyPrefix,
      length: companyPrefixLength,
      partitionValue: partitionEntry.partitionValue,
      companyPrefixBits: partitionEntry.companyPrefixBits,
      itemReferenceBits: partitionEntry.itemReferenceBits,
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
    // Validate serial number
    if (serialNumber < 0 || serialNumber > maxSerialNumber) {
      throw BarcodeException('Serial number must be between 0 and $maxSerialNumber', 'INVALID_SERIAL_NUMBER');
    }

    // Normalize barcode to GTIN-14
    final gtin14 = normalizeToGtin14(barcode, skipCheckDigitValidation: skipCheckDigitValidation);

    // Extract company prefix information
    final companyPrefixData = extractCompanyPrefix(gtin14, companyPrefixLength);

    // Parse GTIN components
    final indicatorDigit = int.parse(gtin14.substring(0, 1));
    final companyPrefixValue = int.parse(companyPrefixData.prefix);

    // Extract the pure item reference (without indicator digit)
    final itemReferenceStart = 1 + companyPrefixLength;
    final itemReferenceEnd = 13; // Before check digit
    final pureItemReference = gtin14.substring(itemReferenceStart, itemReferenceEnd);
    final itemReferenceValue = int.parse(pureItemReference);

    // Combine indicator digit with item reference as specified in EPC standard.
    // The indicator digit goes in the leftmost position of the combined field.
    final itemReferenceDigits = 12 - companyPrefixLength;
    final maxPureItemReference = int.parse('9' * itemReferenceDigits);
    final combinedItemReference = (indicatorDigit * (maxPureItemReference + 1)) + itemReferenceValue;

    // Validate combined item reference fits in allocated bits
    final maxCombinedItemReference = (1 << companyPrefixData.itemReferenceBits) - 1;
    if (combinedItemReference > maxCombinedItemReference) {
      throw const BarcodeException('Combined item reference exceeds bit allocation', 'ITEM_REFERENCE_BIT_OVERFLOW');
    }

    // Build SGTIN-96 binary representation using BigInt for 96-bit precision
    BigInt epc = BigInt.zero;

    // Header (8 bits)
    epc |= (BigInt.from(_sgtinHeader) & BigInt.from(0xFF)) << 88; // Bits 95-88

    // Filter (3 bits)
    epc |= (BigInt.from(filterValue.value) & BigInt.from(0x7)) << 85; // Bits 87-85

    // Partition (3 bits)
    epc |= (BigInt.from(companyPrefixData.partitionValue) & BigInt.from(0x7)) << 82; // Bits 84-82

    // Company Prefix (variable bits)
    final companyPrefixMask = (BigInt.one << companyPrefixData.companyPrefixBits) - BigInt.one;
    epc |= (BigInt.from(companyPrefixValue) & companyPrefixMask) << (82 - companyPrefixData.companyPrefixBits); // After partition bits

    // Item Reference (variable bits)
    final itemReferenceMask = (BigInt.one << companyPrefixData.itemReferenceBits) - BigInt.one;
    epc |= (BigInt.from(combinedItemReference) & itemReferenceMask) << 38; // Bits (81-prefix_bits) to 38

    // Serial Number (38 bits)
    epc |= BigInt.from(serialNumber) & BigInt.from(0x3FFFFFFFFF); // Bits 37-0

    // Convert to hex string (24 hex digits for 96 bits)
    return epc.toRadixString(16).toUpperCase().padLeft(24, '0');
  }

  @override
  BarcodeData decodeFromEpc(String epcHex) {
    if (epcHex.isEmpty) {
      throw const BarcodeException('EPC hex string cannot be empty', 'EMPTY_EPC');
    }

    // Remove any non-hex characters and convert to uppercase
    final cleanHex = epcHex.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();

    // Validate hex string length (24 hex chars = 96 bits)
    if (cleanHex.length != 24) {
      throw BarcodeException('EPC hex string must be 24 characters (96 bits), got ${cleanHex.length}', 'INVALID_EPC_LENGTH');
    }

    // Convert hex to BigInt for 96-bit precision
    final epc = BigInt.parse(cleanHex, radix: 16);

    // Extract header (bits 95-88)
    final header = ((epc >> 88) & BigInt.from(0xFF)).toInt();
    if (header != _sgtinHeader) {
      throw BarcodeException('Invalid SGTIN-96 header: 0x${header.toRadixString(16).toUpperCase()}, expected 0x${_sgtinHeader.toRadixString(16).toUpperCase()}', 'INVALID_HEADER');
    }

    // Extract filter (bits 87-85)
    final filterValue = ((epc >> 85) & BigInt.from(0x7)).toInt();
    final filter = EpcFilter.values.firstWhere(
      (f) => f.value == filterValue,
      orElse: () => EpcFilter.allOthers,
    );

    // Extract partition (bits 84-82)
    final partitionValue = ((epc >> 82) & BigInt.from(0x7)).toInt();
    final partitionEntry = _getPartitionEntryByValue(partitionValue);
    if (partitionEntry == null) {
      throw BarcodeException('Invalid partition value: $partitionValue', 'INVALID_PARTITION');
    }

    // Extract company prefix (variable bits after partition)
    final companyPrefixShift = 82 - partitionEntry.companyPrefixBits;
    final companyPrefixMask = (BigInt.one << partitionEntry.companyPrefixBits) - BigInt.one;
    final companyPrefixValue = ((epc >> companyPrefixShift) & companyPrefixMask).toInt();

    // Extract item reference (variable bits after company prefix)
    final itemReferenceShift = 38;
    final itemReferenceMask = (BigInt.one << partitionEntry.itemReferenceBits) - BigInt.one;
    final combinedItemReference = ((epc >> itemReferenceShift) & itemReferenceMask).toInt();

    // Extract serial number (bits 37-0)
    final serialNumber = (epc & BigInt.from(0x3FFFFFFFFF)).toInt();

    // Reconstruct GTIN from EPC components.
    // The item reference in EPC combines the indicator digit and actual item
    // reference.
    final itemReferenceDigits = 12 - partitionEntry.companyPrefixLength;

    // Separate the indicator digit from the pure item reference.
    // The indicator digit occupies the leftmost position in the combined item
    // reference.
    final maxPureItemReference = int.parse('9' * itemReferenceDigits);
    final indicatorDigit = combinedItemReference ~/ (maxPureItemReference + 1);
    final pureItemReference = combinedItemReference % (maxPureItemReference + 1);

    // Build GTIN-14 components
    final companyPrefix = companyPrefixValue.toString().padLeft(partitionEntry.companyPrefixLength, '0');
    final itemReference = pureItemReference.toString().padLeft(itemReferenceDigits, '0');

    // Construct partial GTIN without check digit
    final partialGtin = '${indicatorDigit.toString()}$companyPrefix$itemReference';

    // Calculate and append check digit
    final checkDigit = calculateCheckDigit(partialGtin);
    final gtin14 = partialGtin + checkDigit;

    // Determine original barcode format based on leading zeros
    BarcodeFormat format;
    String originalBarcode;

    if (gtin14.startsWith('00')) {
      // UPC-12: Remove leading "00"
      format = BarcodeFormat.upc12;
      originalBarcode = gtin14.substring(2);
    } else if (gtin14.startsWith('0')) {
      // EAN-13: Remove leading "0"
      format = BarcodeFormat.ean13;
      originalBarcode = gtin14.substring(1);
    } else {
      // EAN-14: Keep as is
      format = BarcodeFormat.ean14;
      originalBarcode = gtin14;
    }

    return BarcodeData(
      gtin: originalBarcode,
      companyPrefix: companyPrefix,
      itemReference: itemReference,
      serialNumber: serialNumber.toString(),
      format: format,
      filter: filter,
      isValid: true,
    );
  }

  @override
  String? extractPrefixFromBarcode(String barcode, int prefixLength, {bool skipCheckDigitValidation = false}) {
    if (barcode.isEmpty || prefixLength <= 0) {
      return null;
    }

    try {
      // Normalize the barcode to GTIN-14
      final gtin14 = normalizeToGtin14(barcode, skipCheckDigitValidation: skipCheckDigitValidation);

      // Check if the GTIN-14 has enough length for the prefix.
      // GTIN-14 format: 1 digit indicator + prefix + rest
      if (gtin14.length >= 1 + prefixLength) {
        // Extract the prefix (skip the first digit which is the indicator)
        final prefix = gtin14.substring(1, 1 + prefixLength);

        // Validate that the prefix is not empty and contains only digits
        if (prefix.isNotEmpty && RegExp(r'^\d+$').hasMatch(prefix)) {
          return prefix;
        }
      }
      return null;
    } catch (e) {
      // Return null if any error occurs during extraction
      return null;
    }
  }

  @override
  int generateSerial({String? barcode}) {
    // SGTIN-96 supports 38-bit serial (max 274,877,906,943).
    // Random().nextInt() only supports up to 2^32, so combine two randoms.
    final random = Random();
    final high = random.nextInt(1 << 6); // 6 bits
    final low = random.nextInt(1 << 32); // 32 bits
    return (high << 32) | low;
  }
}
