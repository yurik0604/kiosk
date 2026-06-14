import 'reader_vendor.dart';

class ReaderConfig {
  const ReaderConfig({
    required this.vendor,
    required this.host,
    this.port = 5084,
    this.antennaMask = 0xFFFF,
    this.txPowerDbm = 30.0,
    this.preventDuplicates = true,
  });

  /// Which driver/plugin handles this reader.
  final ReaderVendor vendor;

  /// IPv4/host of the reader (LLRP devices) or empty for SDK-managed transports.
  final String host;

  /// Standard LLRP TCP port is 5084.
  final int port;

  /// Bitmask of enabled antenna ports (bit 0 = antenna 1).
  /// `0xFFFF` = all antennas, vendor will clamp to its actual count.
  final int antennaMask;

  /// Tx power in dBm; driver maps to the reader's power-table index and the
  /// reader clamps to its allowed range. The actual emitted power may differ.
  final double txPowerDbm;

  /// When true the native driver suppresses repeat EPCs within the current
  /// inventory run. List clears on every `startInventory`.
  final bool preventDuplicates;

  ReaderConfig copyWith({
    ReaderVendor? vendor,
    String? host,
    int? port,
    int? antennaMask,
    double? txPowerDbm,
    bool? preventDuplicates,
  }) {
    return ReaderConfig(
      vendor: vendor ?? this.vendor,
      host: host ?? this.host,
      port: port ?? this.port,
      antennaMask: antennaMask ?? this.antennaMask,
      txPowerDbm: txPowerDbm ?? this.txPowerDbm,
      preventDuplicates: preventDuplicates ?? this.preventDuplicates,
    );
  }

  Map<String, dynamic> toChannelMap() => {
        'vendor': vendor.id,
        'host': host,
        'port': port,
        'antennaMask': antennaMask,
        'txPowerDbm': txPowerDbm,
        'preventDuplicates': preventDuplicates,
      };
}
