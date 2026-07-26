/// Supported reader vendors. Add a value here when wiring a new driver,
/// then register a factory in `RfidReaderRegistry`.
enum ReaderVendor {
  sensormaticIdx4000(
    'sensormatic_idx4000',
    'Sensormatic IDX-4000',
    honorsRfOverrides: false,
  );

  const ReaderVendor(
    this.id,
    this.displayName, {
    required this.honorsRfOverrides,
  });

  /// Stable identifier persisted in config and sent over the platform channel.
  final String id;

  /// Human-readable label for settings UI.
  final String displayName;

  /// True if the driver actually pushes tx power / antenna mask to the reader
  /// over LLRP or its SDK. False if the reader manages RF on its own and
  /// ignores those fields. Drives the "reader-managed" UI hint.
  final bool honorsRfOverrides;

  static ReaderVendor? fromId(String? id) {
    if (id == null) return null;
    for (final v in ReaderVendor.values) {
      if (v.id == id) return v;
    }
    return null;
  }

  /// Resolve a vendor from the backend's human label (the kiosk
  /// `rfid_config.vendor` value, e.g. `"Sensormatic IDX-4000"`). Matching is
  /// case-insensitive. Returns null when no vendor matches.
  static ReaderVendor? fromDisplayName(String? displayName) {
    if (displayName == null) return null;
    final needle = displayName.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final v in ReaderVendor.values) {
      if (v.displayName.toLowerCase() == needle) return v;
    }
    return null;
  }
}
