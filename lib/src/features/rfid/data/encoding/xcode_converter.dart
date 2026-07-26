/// XCode EPC Encoder/Decoder
/// Encodes and decodes XCode-encoded EPC hex strings.
/// Supports both 96-bit (no encryption) and 128-bit (AES-256 ECB encrypted)
/// tag chips. Supports both numeric and alpha-numeric barcode encodings.
/// Implements BarcodeConverter interface for integration with
/// BarcodeConverterFactory.
library;

import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../../../../core/logging/app_logger.dart';
import 'barcode_converter.dart';
import 'rcode_converter.dart';

/// AES-256 ECB encryption key for XCode encoding (used only for 128-bit tags).
class _XCodeKey {
  static final Uint8List key = Uint8List.fromList([
    0x47, 0x2D, 0x43, 0x6F, 0x64, 0x65, 0x20, 0x41,
    0x72, 0x6B, 0x61, 0x64, 0x79, 0x20, 0x50, 0x61,
    0x6C, 0x61, 0x72, 0x79, 0x61, 0x20, 0x49, 0x6E,
    0x76, 0x65, 0x6E, 0x74, 0x6F, 0x72, 0x20, 0x21,
  ]);
}

/// Bit array with bit-level get/set operations.
/// Supports 96-bit (12 bytes) and 128-bit (16 bytes / AES block) modes.
class _BitArray {
  static const int _aesBlockSize = 16;

  final int _totalBits;
  final int _byteSize;
  final Uint8List _data;

  _BitArray(this._totalBits)
      : _byteSize = _totalBits == 128 ? _aesBlockSize : (_totalBits + 7) ~/ 8,
        _data = Uint8List(_totalBits == 128 ? _aesBlockSize : (_totalBits + 7) ~/ 8);

  /// Parse a hex string into the bit array.
  /// Accepts hex strings matching the byte size (24 chars for 96-bit, 32 chars
  /// for 128-bit).
  bool fromHexString(String hex) {
    if (hex.length != _byteSize * 2) return false;
    try {
      for (var i = 0; i < _byteSize; i++) {
        _data[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Convert bit array to uppercase hex string.
  String toHexString() {
    final buffer = StringBuffer();
    for (var i = 0; i < _byteSize; i++) {
      buffer.write(_data[i].toRadixString(16).padLeft(2, '0').toUpperCase());
    }
    return buffer.toString();
  }

  /// Get [count] bits starting at [position] (MSB-first, bit 0 is the highest
  /// bit of byte 0).
  bool getBits(int position, int count, List<int> outValue) {
    if (position < 0 || count <= 0 || position + count > _totalBits) return false;

    int value = 0;
    for (var i = 0; i < count; i++) {
      final bitIndex = position + i;
      final byteIndex = bitIndex ~/ 8;
      final bitOffset = 7 - (bitIndex % 8);
      final bit = (_data[byteIndex] >> bitOffset) & 1;
      value = (value << 1) | bit;
    }
    outValue[0] = value;
    return true;
  }

  /// Set [count] bits starting at [position] to [value] (MSB-first).
  void setBits(int position, int count, int value) {
    for (var i = count - 1; i >= 0; i--) {
      final bitIndex = position + i;
      final byteIndex = bitIndex ~/ 8;
      final bitOffset = 7 - (bitIndex % 8);
      if ((value & 1) != 0) {
        _data[byteIndex] |= (1 << bitOffset);
      } else {
        _data[byteIndex] &= ~(1 << bitOffset);
      }
      value >>= 1;
    }
  }

  /// Encrypt the data using AES-256 ECB.
  /// Only valid for 128-bit mode (requires 16-byte AES block).
  bool encrypt(Uint8List key) {
    if (_totalBits != 128) return false;
    try {
      final cipher = ECBBlockCipher(AESEngine())
        ..init(true, KeyParameter(key));
      final output = Uint8List(_aesBlockSize);
      cipher.processBlock(_data, 0, output, 0);
      _data.setRange(0, _aesBlockSize, output);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Decrypt the data using AES-256 ECB.
  /// Only valid for 128-bit mode (requires 16-byte AES block).
  bool decrypt(Uint8List key) {
    if (_totalBits != 128) return false;
    try {
      final cipher = ECBBlockCipher(AESEngine())
        ..init(false, KeyParameter(key));
      final output = Uint8List(_aesBlockSize);
      cipher.processBlock(_data, 0, output, 0);
      _data.setRange(0, _aesBlockSize, output);
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// XCode implementation of barcode converter.
///
/// Supports configurable tag chip size:
/// - 96-bit (default): No AES encryption, outputs 24 hex chars (12 bytes)
/// - 128-bit: AES-256 ECB encrypted, outputs 32 hex chars (16 bytes)
///
/// XCode EPC Structure (96-bit data layout):
///
/// Numeric mode (header 0xC):
/// - Header (4 bits): 0xC
/// - Customer ID (8 bits)
/// - Filter (3 bits): SGTIN-style packaging filter (POS, Case, Pallet, etc.)
/// - Leading zeros count (4 bits)
/// - Numeric value (54 bits)
/// - Serial number (23 bits)
///
/// Alpha-numeric mode (header 0xE):
/// - Header (4 bits): 0xE
/// - Customer ID (8 bits)
/// - Filter (3 bits): SGTIN-style packaging filter (POS, Case, Pallet, etc.)
/// - Character/digit map (15 bits)
/// - Value data (55 bits): digits + characters
/// - Serial number (11 bits)
class XCodeConverter implements BarcodeConverter {
  static const String _charMap = r'THEQUICKBROWNF/XJ\MPS-V:LAZYD G';

  static const int _bitsChar = 5;
  static const int _bitsTotal = 96;

  static const int _bitsHeader = 4;
  static const int _bitsCustomer = 8;
  static const int _bitsFilter = 3;

  static const int _bitsNumericMap = 4;
  static const int _bitsNumericValue = 54;
  static const int _bitsNumericSerial = 23;

  static const int _bitsAlphaMap = 15;
  static const int _bitsAlphaValue = 55;
  static const int _bitsAlphaSerial = 11;

  static const int _numericMaxLen = 18;
  static const int _numericMaxLead0s = 15;
  static const int _numericMaxSerialValue = (1 << _bitsNumericSerial) - 1;
  static const int _numericHeaderValue = 0xC;

  static const int _alphaMaxLen = _bitsAlphaMap;
  static const int _alphaMaxLenChar = 11;
  static const int _alphaMaxSerialValue = (1 << _bitsAlphaSerial) - 1;
  static const int _alphaHeaderValue = 0xE;
  static const int _alphaEndOfValue = 0x1F;

  static const Map<int, int> _mapNChar2NDigit = {
    1: 14, 2: 13, 3: 12, 4: 10, 5: 9,
    6: 7, 7: 6, 8: 4, 9: 2, 10: 1, 11: 0,
  };

  static const Map<int, int> _mapNDigit2NChar = {
    14: 1, 13: 2, 12: 3, 11: 3, 10: 4,
    9: 5, 8: 5, 7: 6, 6: 7, 5: 7,
    4: 8, 3: 8, 2: 9, 1: 10, 0: 11,
  };

  final Map<int, String> _mapBits2Char = {};
  final Map<String, int> _mapChar2Bits = {};

  /// Lazy RCode fallback decoder — only created if a non-XCode EPC is
  /// encountered.
  RCodeConverter? _rcodeConverter;

  /// Tag chip EPC size in bits. Supported values: 96 (default) and 128.
  /// - 96-bit: No AES encryption, produces 24 hex char EPC
  /// - 128-bit: AES-256 ECB encrypted, produces 32 hex char EPC
  final int tagChipSize;

  XCodeConverter({this.tagChipSize = 96}) {
    if (tagChipSize != 96 && tagChipSize != 128) {
      throw ArgumentError('tagChipSize must be 96 or 128, got $tagChipSize');
    }
    for (var i = 0; i < _charMap.length; i++) {
      _mapBits2Char[i] = _charMap[i];
      _mapChar2Bits[_charMap[i]] = i;
    }
  }

  bool get _useEncryption => tagChipSize == 128;

  /// Expected hex string length for the configured tag chip size.
  int get _expectedHexLength => tagChipSize == 128 ? 32 : 24;

  @override
  BarcodeData decodeFromEpc(String epcHex) {
    if (epcHex.isEmpty) {
      throw const BarcodeException('EPC hex string cannot be empty', 'EMPTY_EPC');
    }

    final cleanHex = epcHex.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();

    if (cleanHex.length != _expectedHexLength) {
      throw BarcodeException(
        'XCode EPC hex string must be $_expectedHexLength characters '
        '($tagChipSize bits), got ${cleanHex.length}',
        'INVALID_EPC_LENGTH',
      );
    }

    final bits = _BitArray(tagChipSize);
    if (!bits.fromHexString(cleanHex)) {
      throw const BarcodeException('Failed to parse EPC hex string', 'PARSE_ERROR');
    }

    if (_useEncryption) {
      if (!bits.decrypt(_XCodeKey.key)) {
        throw const BarcodeException('Decryption failed', 'DECRYPT_ERROR');
      }
    }

    var pos = 0;
    final val = [0];

    // Get header
    if (!bits.getBits(pos, _bitsHeader, val)) {
      throw const BarcodeException('Failed to read header', 'INTERNAL_ERROR');
    }
    final headerValue = val[0];

    final bool isAlpha;
    if (headerValue == _alphaHeaderValue) {
      isAlpha = true;
    } else if (headerValue == _numericHeaderValue) {
      isAlpha = false;
    } else {
      // Not an XCode EPC — try RCode decode as fallback
      AppLogger.instance.d(
          'XCode header 0x${headerValue.toRadixString(16).toUpperCase()} not recognized, falling back to RCode decode for EPC: $epcHex');
      _rcodeConverter ??= RCodeConverter();
      final rcodeResult = _rcodeConverter!.decodeFromEpc(epcHex);
      return BarcodeData(
        gtin: rcodeResult.gtin,
        companyPrefix: rcodeResult.companyPrefix,
        itemReference: rcodeResult.itemReference,
        serialNumber: rcodeResult.serialNumber,
        format: rcodeResult.format,
        filter: rcodeResult.filter,
        isValid: rcodeResult.isValid,
        decodedByStandard: 'rcode',
      );
    }
    pos += _bitsHeader;

    // Get customer ID
    bits.getBits(pos, _bitsCustomer, val);
    final customerId = val[0];
    pos += _bitsCustomer;

    // Get filter (SGTIN-style packaging filter — 3 bits)
    bits.getBits(pos, _bitsFilter, val);
    final filter = EpcFilter.values.firstWhere(
      (f) => f.value == val[0],
      orElse: () => EpcFilter.allOthers,
    );
    pos += _bitsFilter;

    String barcode;
    int serial;

    if (isAlpha) {
      // Get map
      bits.getBits(pos, _bitsAlphaMap, val);
      final map = val[0];
      pos += _bitsAlphaMap;

      var cntDigits = 0;
      var cntChars = 0;
      for (var i = 0; i < _bitsAlphaMap; i++) {
        if ((map & (1 << i)) != 0) {
          cntDigits++;
        } else {
          cntChars++;
        }
      }

      // Get digits
      final nBits = _getNumOfBitsForDigits(cntDigits);
      bits.getBits(pos, nBits, val);
      pos += nBits;

      final digits = <String>[];
      var digitValue = val[0];
      while (digitValue > 0) {
        digits.add(String.fromCharCode('0'.codeUnitAt(0) + (digitValue % 10)));
        digitValue ~/= 10;
      }
      final reversedDigits = digits.reversed.toList();

      // Get chars
      final maxChars = min(cntChars, _mapNDigit2NChar[cntDigits] ?? 0);
      final chars = <String>[];
      for (var i = 0; i < maxChars; i++) {
        bits.getBits(pos, _bitsChar, val);
        pos += _bitsChar;
        if (val[0] != _alphaEndOfValue) {
          chars.add(_mapBits2Char[val[0]] ?? '');
        } else {
          break;
        }
      }

      // Assemble barcode
      final barcodeChars = List<String>.filled(_bitsAlphaMap, '');
      var iDigit = 0;
      var iChar = 0;
      for (var i = 0; i < _bitsAlphaMap; i++) {
        if ((map & (1 << i)) != 0) {
          if (iDigit < reversedDigits.length) {
            barcodeChars[i] = reversedDigits[iDigit++];
          }
        } else {
          if (iChar < chars.length) {
            barcodeChars[i] = chars[iChar++];
          }
        }
      }
      barcode = barcodeChars.join();

      // Get serial
      bits.getBits(_bitsTotal - _bitsAlphaSerial, _bitsAlphaSerial, val);
      serial = val[0];
    } else {
      // Numeric mode
      // Get leading zeros count
      bits.getBits(pos, _bitsNumericMap, val);
      barcode = ''.padRight(val[0], '0');
      pos += _bitsNumericMap;

      // Get numeric value
      bits.getBits(pos, _bitsNumericValue, val);
      if (val[0] > 0) {
        barcode += val[0].toString();
      }
      pos += _bitsNumericValue;

      // Get serial
      bits.getBits(pos, _bitsNumericSerial, val);
      serial = val[0];
    }

    return BarcodeData(
      gtin: barcode,
      companyPrefix: customerId.toString(),
      itemReference: barcode,
      serialNumber: serial.toString(),
      format: BarcodeFormat.gtin14,
      filter: filter,
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
    if (customerXcodePrefix == null) {
      throw const BarcodeException(
        'customerXcodePrefix is required for XCode encoding',
        'MISSING_XCODE_PREFIX',
      );
    }

    if (customerXcodePrefix > 255) {
      throw const BarcodeException(
        'Customer ID supported up to 255',
        'INVALID_CUSTOMER_ID',
      );
    }

    if (barcode.isEmpty) {
      throw const BarcodeException(
        'Barcode is not specified',
        'EMPTY_BARCODE',
      );
    }

    var upperBarcode = barcode.toUpperCase();

    var cntDigits = 0;
    var cntLead0s = 0;
    var cntChars = 0;
    var alphaMap = 0;
    var alphaNum = 0;

    for (var i = 0; i < upperBarcode.length; i++) {
      final c = upperBarcode[i];
      if (c.codeUnitAt(0) >= '0'.codeUnitAt(0) &&
          c.codeUnitAt(0) <= '9'.codeUnitAt(0)) {
        if (cntLead0s == cntDigits && c == '0') {
          cntLead0s++;
        }
        alphaNum = 10 * alphaNum + (c.codeUnitAt(0) - '0'.codeUnitAt(0));
        alphaMap |= (1 << (cntDigits + cntChars));
        cntDigits++;
      } else {
        cntChars++;
        if (!_mapChar2Bits.containsKey(c)) {
          throw BarcodeException(
            "Barcode contains unsupported character '$c'",
            'UNSUPPORTED_CHAR',
          );
        }
      }
    }

    final isAlpha = cntChars > 0;

    if (isAlpha) {
      if (cntLead0s > 0) {
        alphaMap >>= cntLead0s;
        cntDigits -= cntLead0s;
        cntLead0s = 0;
        upperBarcode = upperBarcode.replaceFirst(RegExp(r'^0+'), '');
      }

      if (cntChars + cntDigits > _alphaMaxLen) {
        throw BarcodeException(
          'Alpha-numeric barcode too long - max length $_alphaMaxLen letters and digits',
          'BARCODE_TOO_LONG',
        );
      }

      if (cntChars > _alphaMaxLenChar) {
        throw BarcodeException(
          'Alpha-numeric barcode supports at max $_alphaMaxLenChar letters',
          'TOO_MANY_CHARS',
        );
      }

      final nBits = _getNumOfBitsForDigits(cntDigits);
      if (cntChars * _bitsChar + nBits > _bitsAlphaValue) {
        throw BarcodeException(
          'Alpha-numeric barcode with $cntChars letters supports up to ${_mapNChar2NDigit[cntChars]} digits',
          'DIGIT_OVERFLOW',
        );
      }
    } else {
      if (cntDigits > _numericMaxLen) {
        throw BarcodeException(
          'Numeric barcode supports at max $_numericMaxLen digits',
          'BARCODE_TOO_LONG',
        );
      }

      if (cntLead0s > _numericMaxLead0s) {
        throw BarcodeException(
          'Numeric barcode supports at max $_numericMaxLead0s leading zeros',
          'TOO_MANY_LEADING_ZEROS',
        );
      }

      upperBarcode = upperBarcode.replaceFirst(RegExp(r'^0+'), '');
    }

    // Validate serial
    if (isAlpha) {
      if (serialNumber > _alphaMaxSerialValue) {
        throw BarcodeException(
          'Serial number for alpha-numeric barcode can be up to $_alphaMaxSerialValue',
          'SERIAL_OVERFLOW',
        );
      }
    } else {
      if (serialNumber > _numericMaxSerialValue) {
        throw BarcodeException(
          'Serial number for numeric barcode can be up to $_numericMaxSerialValue',
          'SERIAL_OVERFLOW',
        );
      }
    }

    // Always pack data into 96-bit layout
    var pos = 0;
    final bits = _BitArray(tagChipSize);

    // Set header
    bits.setBits(pos, _bitsHeader, isAlpha ? _alphaHeaderValue : _numericHeaderValue);
    pos += _bitsHeader;

    // Set customer
    bits.setBits(pos, _bitsCustomer, customerXcodePrefix);
    pos += _bitsCustomer;

    // Set filter (SGTIN-style packaging filter — 3 bits)
    bits.setBits(pos, _bitsFilter, filterValue.value & 0x7);
    pos += _bitsFilter;

    // Set map
    if (isAlpha) {
      bits.setBits(pos, _bitsAlphaMap, alphaMap);
      pos += _bitsAlphaMap;
    } else {
      bits.setBits(pos, _bitsNumericMap, cntLead0s);
      pos += _bitsNumericMap;
    }

    // Set value
    if (isAlpha) {
      final nDigits = _getNumberOfDigits(alphaNum);
      var nBits = _getNumOfBitsForDigits(nDigits);

      bits.setBits(pos, nBits, alphaNum);
      pos += nBits;

      for (var i = 0; i < upperBarcode.length; i++) {
        final c = upperBarcode[i];
        if (!(c.codeUnitAt(0) >= '0'.codeUnitAt(0) &&
            c.codeUnitAt(0) <= '9'.codeUnitAt(0))) {
          if (nBits + _bitsChar > _bitsAlphaValue) {
            throw const BarcodeException(
              'Internal encoding error',
              'ENCODE_ERROR',
            );
          }
          bits.setBits(pos, _bitsChar, _mapChar2Bits[c]!);
          pos += _bitsChar;
          nBits += _bitsChar;
        }
      }

      if (nBits + _bitsChar <= _bitsAlphaValue) {
        bits.setBits(pos, _bitsChar, _alphaEndOfValue);
      }

      pos = _bitsTotal - _bitsAlphaSerial;
    } else {
      int value;
      if (upperBarcode.isNotEmpty) {
        value = int.tryParse(upperBarcode) ?? 0;
      } else {
        value = 0;
      }

      bits.setBits(pos, _bitsNumericValue, value);
      pos += _bitsNumericValue;
    }

    // Set serial
    bits.setBits(pos, isAlpha ? _bitsAlphaSerial : _bitsNumericSerial, serialNumber);

    // Encrypt only for 128-bit tags
    if (_useEncryption) {
      if (!bits.encrypt(_XCodeKey.key)) {
        throw const BarcodeException('Encryption failed', 'ENCRYPT_ERROR');
      }
    }

    return bits.toHexString();
  }

  @override
  String calculateCheckDigit(String partialBarcode) {
    // XCode does not use check digits
    return '';
  }

  @override
  bool validateBarcode(String barcode) {
    return validateBarcodeDetailed(barcode) == null;
  }

  /// Validates the barcode and returns a structured error key, or null if valid.
  ///
  /// Error keys use colon-separated format: `error_key:param1:param2`
  /// for integration with the localization system.
  ///
  /// Supported characters: A-Z, 0-9, / \ - : (space)
  /// Numeric: max 18 digits, max 15 leading zeros
  /// Alpha-numeric: no leading zeros, max 11 letters, total max 15
  String? validateBarcodeDetailed(String barcode) {
    if (barcode.isEmpty) return 'error_xcode_empty';

    final upper = barcode.toUpperCase();
    var cntDigits = 0;
    var cntChars = 0;
    var cntLead0s = 0;
    final unsupportedChars = <String>{};

    for (var i = 0; i < upper.length; i++) {
      final c = upper[i];
      final isDigit = c.codeUnitAt(0) >= '0'.codeUnitAt(0) &&
          c.codeUnitAt(0) <= '9'.codeUnitAt(0);
      if (isDigit) {
        if (cntLead0s == cntDigits && c == '0') {
          cntLead0s++;
        }
        cntDigits++;
      } else if (_mapChar2Bits.containsKey(c)) {
        cntChars++;
      } else {
        unsupportedChars.add(c);
      }
    }

    if (unsupportedChars.isNotEmpty) {
      final chars = unsupportedChars.join(', ');
      return 'error_xcode_unsupported_char:$chars';
    }

    final isAlpha = cntChars > 0;

    if (isAlpha) {
      if (cntLead0s > 0) {
        return 'error_xcode_leading_zeros_alpha';
      }
      if (cntChars > _alphaMaxLenChar) {
        return 'error_xcode_max_letters:$_alphaMaxLenChar:$cntChars';
      }
      if (cntChars + cntDigits > _alphaMaxLen) {
        return 'error_xcode_max_total:$_alphaMaxLen:${cntChars + cntDigits}';
      }
      final maxDigits = _mapNChar2NDigit[cntChars];
      if (maxDigits == null || cntDigits > maxDigits) {
        final allowed = maxDigits ?? 0;
        return 'error_xcode_digit_limit:$cntChars:$allowed:$cntDigits';
      }
    } else {
      if (cntDigits > _numericMaxLen) {
        return 'error_xcode_max_digits:$_numericMaxLen:$cntDigits';
      }
      if (cntLead0s > _numericMaxLead0s) {
        return 'error_xcode_max_leading_zeros:$_numericMaxLead0s:$cntLead0s';
      }
    }

    return null;
  }

  @override
  String normalizeToGtin14(String barcode, {bool skipCheckDigitValidation = false}) {
    // XCode doesn't use GTIN-14; normalize for comparison only:
    // - Trim whitespace
    // - Uppercase (encoder converts to uppercase)
    return barcode.replaceAll(RegExp(r'\s'), '').toUpperCase();
  }

  @override
  BarcodeFormat getBarcodeFormat(String barcode) {
    return BarcodeFormat.gtin14;
  }

  @override
  CompanyPrefixData extractCompanyPrefix(String gtin14, int companyPrefixLength) {
    return CompanyPrefixData(
      prefix: gtin14,
      length: gtin14.length,
      partitionValue: 0,
      companyPrefixBits: 0,
      itemReferenceBits: 0,
    );
  }

  @override
  String? extractPrefixFromBarcode(
    String barcode,
    int prefixLength, {
    bool skipCheckDigitValidation = false,
  }) {
    return null;
  }

  @override
  int generateSerial({String? barcode}) {
    // XCode serial limits depend on barcode type:
    // - Alpha-numeric: 14 bits (max 16383)
    // - Numeric: 26 bits (max 67108863)
    final isAlpha = barcode != null &&
        barcode.toUpperCase().contains(RegExp(r'[^0-9]'));
    final maxSerial = isAlpha ? _alphaMaxSerialValue : _numericMaxSerialValue;
    return Random().nextInt(maxSerial);
  }

  /// Returns the number of bits needed to represent a number with [numDigits]
  /// decimal digits.
  static int _getNumOfBitsForDigits(int numDigits) {
    if (numDigits <= 0) return 0;
    return (numDigits * log(10) / log(2)).ceil();
  }

  /// Returns the number of decimal digits in [value].
  static int _getNumberOfDigits(int value) {
    if (value == 0) return 0;
    return value.toString().length;
  }
}
