class RfidTag {
  const RfidTag({
    required this.epc,
    required this.readTime,
    this.rssi,
    this.antenna,
    this.channelIndex,
    this.tagSeenCount,
  });

  /// Hex-encoded EPC (no `0x` prefix, upper case).
  final String epc;

  /// First-seen UTC timestamp reported by the reader.
  final DateTime readTime;

  /// Peak RSSI in dBm (LLRP `PeakRSSI`). Null if reader did not include it.
  final int? rssi;

  /// 1-based antenna port that read the tag.
  final int? antenna;

  /// LLRP `ChannelIndex` — useful for frequency-hopping diagnostics.
  final int? channelIndex;

  /// How many times the tag was seen in this report window.
  final int? tagSeenCount;

  Map<String, dynamic> toMap() => {
        'epc': epc,
        'readTime': readTime.toUtc().toIso8601String(),
        'rssi': rssi,
        'antenna': antenna,
        'channelIndex': channelIndex,
        'tagSeenCount': tagSeenCount,
      };

  factory RfidTag.fromMap(Map<dynamic, dynamic> map) {
    final ts = map['readTime'];
    return RfidTag(
      epc: (map['epc'] as String).toUpperCase(),
      readTime: ts is int
          ? DateTime.fromMicrosecondsSinceEpoch(ts, isUtc: true)
          : DateTime.parse(ts as String).toUtc(),
      rssi: (map['rssi'] as num?)?.toInt(),
      antenna: (map['antenna'] as num?)?.toInt(),
      channelIndex: (map['channelIndex'] as num?)?.toInt(),
      tagSeenCount: (map['tagSeenCount'] as num?)?.toInt(),
    );
  }

  @override
  String toString() =>
      'RfidTag(epc=$epc, ant=$antenna, rssi=$rssi, t=$readTime)';
}
