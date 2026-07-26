import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk/src/features/kiosk/domain/kiosk_rfid_config.dart';
import 'package:kiosk/src/features/rfid/domain/reader_vendor.dart';

void main() {
  group('KioskRfidConfig.fromJson', () {
    test('parses the swagger rfid_config example', () {
      final cfg = KioskRfidConfig.fromJson(const {
        'vendor': 'Sensormatic IDX-4000',
        'ip': '192.168.1.50',
        'port': 5084,
        'prevent_duplicates': true,
        'antennas': [1, 2, 3, 4],
        'power': [18, 18, 18, 18],
        'mask': '',
      });

      expect(cfg.vendor, 'Sensormatic IDX-4000');
      expect(cfg.ip, '192.168.1.50');
      expect(cfg.port, 5084);
      expect(cfg.preventDuplicates, isTrue);
      expect(cfg.antennas, [1, 2, 3, 4]);
      expect(cfg.power, [18, 18, 18, 18]);
      expect(cfg.mask, '');
    });

    test('defaults gracefully on an empty/unconfigured object', () {
      final cfg = KioskRfidConfig.fromJson(const {});
      expect(cfg.vendor, '');
      expect(cfg.ip, '');
      expect(cfg.port, isNull);
      expect(cfg.preventDuplicates, isFalse);
      expect(cfg.antennas, isEmpty);
      expect(cfg.power, isEmpty);
      expect(cfg.isConfigured, isFalse);
    });
  });

  group('KioskRfidConfig.toReaderConfig', () {
    test('maps vendor label, host, port and prevent-duplicates through', () {
      final reader = KioskRfidConfig.fromJson(const {
        'vendor': 'Sensormatic IDX-4000',
        'ip': '192.168.1.50',
        'port': 5084,
        'prevent_duplicates': true,
        'antennas': [1, 2, 3, 4],
        'power': [18, 18, 18, 18],
        'mask': '',
      }).toReaderConfig();

      expect(reader.vendor, ReaderVendor.sensormaticIdx4000);
      expect(reader.host, '192.168.1.50');
      expect(reader.port, 5084);
      expect(reader.preventDuplicates, isTrue);
    });

    test('converts 1-based antenna ports to a bitmask (bit 0 = antenna 1)', () {
      const base = KioskRfidConfig(vendor: 'Sensormatic IDX-4000', ip: 'x');

      // [1,2,3,4] → 0b1111 = 0xF
      expect(
        base.copyWithAntennas(const [1, 2, 3, 4]).toReaderConfig().antennaMask,
        0xF,
      );
      // [1] → 0b0001
      expect(
        base.copyWithAntennas(const [1]).toReaderConfig().antennaMask,
        0x1,
      );
      // [2,4] → 0b1010 = 0xA
      expect(
        base.copyWithAntennas(const [2, 4]).toReaderConfig().antennaMask,
        0xA,
      );
    });

    test('empty antennas → all antennas (0xFFFF)', () {
      const cfg = KioskRfidConfig(vendor: 'Sensormatic IDX-4000', ip: 'x');
      expect(cfg.toReaderConfig().antennaMask, 0xFFFF);
    });

    test('power list collapses to the max dBm; empty → 30.0 default', () {
      const base = KioskRfidConfig(vendor: 'Sensormatic IDX-4000', ip: 'x');
      expect(base.copyWithPower(const [18, 20, 15]).toReaderConfig().txPowerDbm,
          20.0);
      expect(base.toReaderConfig().txPowerDbm, 30.0);
    });

    test('port defaults to 5084 when null', () {
      const cfg = KioskRfidConfig(vendor: 'Sensormatic IDX-4000', ip: 'x');
      expect(cfg.toReaderConfig().port, 5084);
    });

    test('unknown/blank vendor falls back to the first known vendor', () {
      const cfg = KioskRfidConfig(vendor: '', ip: 'x');
      expect(cfg.toReaderConfig().vendor, ReaderVendor.values.first);
    });
  });
}

/// Small helpers to vary a single list field in the mapping tests without a
/// full copyWith on the production model.
extension on KioskRfidConfig {
  KioskRfidConfig copyWithAntennas(List<int> antennas) => KioskRfidConfig(
        vendor: vendor,
        ip: ip,
        port: port,
        preventDuplicates: preventDuplicates,
        antennas: antennas,
        power: power,
        mask: mask,
      );

  KioskRfidConfig copyWithPower(List<int> power) => KioskRfidConfig(
        vendor: vendor,
        ip: ip,
        port: port,
        preventDuplicates: preventDuplicates,
        antennas: antennas,
        power: power,
        mask: mask,
      );
}
