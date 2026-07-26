/// RCode EPC Decoder
/// Decodes RCode-encoded 96-bit EPC hex strings into barcode, customer ID, and
/// serial number. Supports both numeric and alpha-numeric barcode encodings.
library;

import 'dart:math';

import 'barcode_converter.dart';

/// RCode decode-only converter
///
/// RCode EPC Structure (96-bit):
/// - Sign bit (1 bit): 0 = numeric, 1 = alpha-numeric
/// - Customer ID (10 bits)
/// - Serial Number (22 bits numeric / 17 bits alpha)
/// - Barcode data (remaining bits)
class RCodeConverter {
  static const String _charMap = r'/\ABCDEFGHIJKLMNOPQRSTUVWXYZ -:.';
  static const String _charEol = '/';

  static const int _bitsChar = 5;

  static const int _bitsSign = 1;
  static const int _bitsCustomer = 10;

  static const int _bitsNumericMap = 3;
  static const int _bitsNumericValue = 60;
  static const int _bitsNumericSerial = 22;

  static const int _bitsAlphaMap = 14;
  static const int _bitsAlphaValue = 54;
  static const int _bitsAlphaSerial = 17;

  /// Mapping from 5-bit binary strings to characters.
  final Map<String, String> _mapBits2Char = {};

  RCodeConverter() {
    for (var i = 0; i < _charMap.length; i++) {
      final bin = i.toRadixString(2).padLeft(_bitsChar, '0');
      _mapBits2Char[bin] = _charMap[i];
    }
  }

  /// Decode RCode EPC hex string to barcode data
  BarcodeData decodeFromEpc(String epcHex) {
    if (epcHex.isEmpty) {
      throw const BarcodeException('EPC hex string cannot be empty', 'EMPTY_EPC');
    }

    final cleanHex = String.fromCharCodes(
      epcHex.codeUnits.where((c) =>
          (c >= 48 && c <= 57) || // 0-9
          (c >= 65 && c <= 70) || // A-F
          (c >= 97 && c <= 102), // a-f
      ),
    ).toUpperCase();

    if (cleanHex.length != 24) {
      throw BarcodeException(
        'EPC hex string must be 24 characters (96 bits), got ${cleanHex.length}',
        'INVALID_EPC_LENGTH',
      );
    }

    final binaryEpc = _hexToBits(cleanHex);

    var position = 0;
    final isAlpha = binaryEpc.substring(position, position + _bitsSign) == '1';
    position += _bitsSign;

    final customerBits = binaryEpc.substring(position, position + _bitsCustomer);
    position += _bitsCustomer;
    final customerId = int.parse(customerBits, radix: 2);

    final serialBits = binaryEpc.substring(
      position,
      position + (isAlpha ? _bitsAlphaSerial : _bitsNumericSerial),
    );
    position += isAlpha ? _bitsAlphaSerial : _bitsNumericSerial;

    final serial = int.parse(serialBits, radix: 2);

    final length = isAlpha
        ? (_bitsAlphaMap + _bitsAlphaValue)
        : (_bitsNumericMap + _bitsNumericValue);

    final barcodeBin = binaryEpc.substring(position, position + length);

    final String barcode;
    if (isAlpha) {
      barcode = _decodeAlphaBarcode(barcodeBin);
    } else {
      barcode = _decodeNumericBarcode(barcodeBin);
    }

    return BarcodeData(
      gtin: barcode,
      companyPrefix: customerId.toString(),
      itemReference: barcode,
      serialNumber: serial.toString(),
      format: BarcodeFormat.gtin14,
      filter: EpcFilter.allOthers,
      isValid: true,
    );
  }

  // --- Private decode helpers ---

  String _decodeAlphaBarcode(String barcodeBin) {
    var map = barcodeBin.substring(0, _bitsAlphaMap);
    final val = barcodeBin.substring(_bitsAlphaMap, _bitsAlphaMap + _bitsAlphaValue);

    var cntChars = map.split('').where((c) => c == '1').length;

    if (cntChars == 0) {
      throw const BarcodeException(
        'Invalid alpha-numeric RCode - no characters found',
        'INVALID_RCODE_ALPHA',
      );
    }

    final lastCharPos = (cntChars - 1) * _bitsChar;
    final lastCharInx = map.lastIndexOf('1');
    final lastCharBin = val.substring(lastCharPos, lastCharPos + _bitsChar);

    if (lastCharPos + _bitsChar > _bitsAlphaValue) {
      map = map.substring(0, lastCharInx);
      cntChars--;
    } else {
      if (_mapBits2Char[lastCharBin] != _charEol) {
        final nBits = _getNumOfBitsForDigits(_bitsAlphaMap - cntChars);
        if (cntChars * _bitsChar + nBits > _bitsAlphaValue) {
          map = map.substring(0, lastCharInx);
          cntChars--;
        }
      } else {
        if (lastCharInx + 1 < map.length) {
          map = map.substring(0, lastCharInx + 1);
        }
      }
    }

    final chars = <String>[];
    for (var i = 0; i < cntChars; i++) {
      final curChBit = val.substring(i * _bitsChar, (i + 1) * _bitsChar);
      chars.add(_mapBits2Char[curChBit]!);
    }

    final digitsBin = val.substring(cntChars * _bitsChar, _bitsAlphaValue);
    final cntDigits = map.length - cntChars;
    final digitsValue = BigInt.parse(digitsBin, radix: 2);
    final digits = digitsValue.toString().padLeft(cntDigits, '0');

    final barcode = StringBuffer();
    var id = 0;
    var ic = 0;
    for (var i = 0; i < map.length; i++) {
      if (map[i] == '0') {
        if (id < digits.length) {
          barcode.write(digits[id++]);
        }
      } else {
        if (ic < chars.length) {
          if (chars[ic] == _charEol) break;
          barcode.write(chars[ic++]);
        }
      }
    }

    return barcode.toString();
  }

  String _decodeNumericBarcode(String barcodeBin) {
    final mapValue = int.parse(
      barcodeBin.substring(0, _bitsNumericMap),
      radix: 2,
    );
    final valBits = barcodeBin.substring(
      _bitsNumericMap,
      _bitsNumericMap + _bitsNumericValue,
    );
    final val = BigInt.parse(valBits, radix: 2);

    var barcode = ''.padLeft(mapValue, '0');
    if (val > BigInt.zero) {
      barcode += val.toString();
    }

    return barcode;
  }

  /// Converts a hex string to a binary string representation.
  static String _hexToBits(String hex) {
    final buffer = StringBuffer();
    for (var i = 0; i < hex.length; i++) {
      final nibble = int.parse(hex[i], radix: 16);
      buffer.write(nibble.toRadixString(2).padLeft(4, '0'));
    }
    return buffer.toString();
  }

  /// Returns the number of bits needed to represent a value
  /// with the given number of decimal digits.
  static int _getNumOfBitsForDigits(int numDigits) {
    if (numDigits <= 0) return 0;
    return (numDigits * log(10) / log(2)).ceil();
  }
}
