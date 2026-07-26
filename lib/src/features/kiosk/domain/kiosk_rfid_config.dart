import '../../rfid/domain/reader_config.dart';
import '../../rfid/domain/reader_vendor.dart';

/// RFID reader configuration carried on a [Kiosk] (`rfid_config`).
///
/// Mirrors the backend `rfid_config` JSON exactly (see the `Kiosks` swagger
/// endpoint). `antennas` and `power` are index-aligned lists: `power[i]` is the
/// transmit power (dBm) for antenna port `antennas[i]`.
class KioskRfidConfig {
  const KioskRfidConfig({
    this.vendor = '',
    this.ip = '',
    this.port,
    this.preventDuplicates = false,
    this.antennas = const [],
    this.power = const [],
    this.mask = '',
  });

  /// Reader vendor/model, e.g. `Sensormatic IDX-4000`, `Keonn AdvanReader-160`.
  /// Empty when the reader is unconfigured.
  final String vendor;

  /// Reader host/IP (LLRP devices). Empty when unconfigured.
  final String ip;

  /// Reader TCP port (LLRP standard is 5084). Null when unconfigured.
  final int? port;

  /// When true the reader suppresses repeat EPCs within an inventory run.
  final bool preventDuplicates;

  /// Enabled antenna ports for the vendor, e.g. `[1, 2, 3, 4]`.
  final List<int> antennas;

  /// Per-antenna transmit power in dBm, index-aligned to [antennas].
  final List<int> power;

  /// EPC mask filter string. Empty when no mask is applied.
  final String mask;

  bool get isConfigured => vendor.isNotEmpty && ip.isNotEmpty;

  factory KioskRfidConfig.fromJson(Map<String, dynamic> json) {
    return KioskRfidConfig(
      vendor: json['vendor'] as String? ?? '',
      ip: json['ip'] as String? ?? '',
      port: (json['port'] as num?)?.toInt(),
      preventDuplicates: json['prevent_duplicates'] as bool? ?? false,
      antennas: _intList(json['antennas']),
      power: _intList(json['power']),
      mask: json['mask'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendor': vendor,
      'ip': ip,
      'port': port,
      'prevent_duplicates': preventDuplicates,
      'antennas': antennas,
      'power': power,
      'mask': mask,
    };
  }

  static List<int> _intList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<num>()
        .map((n) => n.toInt())
        .toList(growable: false);
  }

  /// Map this server config onto the app's runtime [ReaderConfig] (the shape the
  /// native driver and settings screen consume).
  ///
  /// Conversions:
  /// - [vendor] (label, e.g. `"Sensormatic IDX-4000"`) → [ReaderVendor] by
  ///   display name, defaulting to the first vendor when unknown/empty.
  /// - [ip] → `host`, [port] → `port` (5084 when null).
  /// - [antennas] ports (`[1, 2, 3, 4]`, bit 0 = antenna 1) → the `antennaMask`
  ///   bitmask; empty → `0xFFFF` (all antennas).
  /// - [power] (per-antenna dBm) → a single `txPowerDbm`, taking the max of the
  ///   list; empty → 30.0.
  /// - [preventDuplicates] passes through.
  ///
  /// [mask] (EPC filter) has no counterpart in [ReaderConfig] today and is not
  /// carried through.
  ReaderConfig toReaderConfig() {
    final resolvedVendor = ReaderVendor.fromDisplayName(vendor) ??
        ReaderVendor.values.first;
    return ReaderConfig(
      vendor: resolvedVendor,
      host: ip,
      port: port ?? 5084,
      antennaMask: _antennasToMask(antennas),
      txPowerDbm: _powerToDbm(power),
      preventDuplicates: preventDuplicates,
    );
  }

  /// Convert a list of 1-based antenna ports to a bitmask (bit 0 = antenna 1).
  /// Empty → `0xFFFF` (all antennas; the vendor clamps to its real count).
  static int _antennasToMask(List<int> antennas) {
    if (antennas.isEmpty) return 0xFFFF;
    var mask = 0;
    for (final port in antennas) {
      if (port >= 1 && port <= 16) mask |= 1 << (port - 1);
    }
    return mask == 0 ? 0xFFFF : mask;
  }

  /// Collapse the per-antenna power list to a single dBm value (the max, so the
  /// strongest configured antenna is honored). Empty → 30.0.
  static double _powerToDbm(List<int> power) {
    if (power.isEmpty) return 30.0;
    return power.reduce((a, b) => a > b ? a : b).toDouble();
  }

  @override
  bool operator ==(Object other) =>
      other is KioskRfidConfig &&
      other.vendor == vendor &&
      other.ip == ip &&
      other.port == port &&
      other.preventDuplicates == preventDuplicates &&
      _listEquals(other.antennas, antennas) &&
      _listEquals(other.power, power) &&
      other.mask == mask;

  @override
  int get hashCode => Object.hash(
        vendor,
        ip,
        port,
        preventDuplicates,
        Object.hashAll(antennas),
        Object.hashAll(power),
        mask,
      );

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
