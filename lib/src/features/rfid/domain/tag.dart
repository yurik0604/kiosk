import '../data/encoding/barcode_converter.dart';
import 'rfid_tag.dart';

/// The kind of tag a [Tag] was produced from.
enum TagType {
  rfid('RFID'),
  qrcode('QRCODE'),
  nfc('NFC'),
  barcode('BARCODE');

  const TagType(this.wireValue);

  /// Server/JSON representation.
  final String wireValue;

  static TagType fromWire(String? value) {
    switch (value) {
      case 'QRCODE':
        return TagType.qrcode;
      case 'NFC':
        return TagType.nfc;
      case 'BARCODE':
        return TagType.barcode;
      case 'RFID':
      default:
        return TagType.rfid;
    }
  }
}

/// The domain tag produced by the tag-processing pipeline.
///
/// This is the "decoded" tag the field app extracts: a raw [RfidTag] read from
/// the reader is decoded into this via [Tag.fromRfidTag], carrying the decoded
/// barcode (GTIN) plus the full decode + RFID metadata in [tagData]. Kept
/// field-for-field compatible with the app's `Tag` (minus the zone-assignment
/// and manual-barcode paths the kiosk doesn't use) so downstream logic matches.
class Tag {
  /// Unique identifier of the tag (the EPC for RFID reads).
  final String uid;

  /// Decoded barcode / GTIN (or raw EPC if decode produced no GTIN).
  final String barcode;

  final TagType tagType;
  final int? countId;
  final int? zoneId;
  final String? batchId;
  final int? userId;
  final DateTime readTime;

  /// Server-assigned last-modified timestamp. `null` for locally-created tags
  /// that have not yet been synced to (or echoed back from) the server.
  final DateTime? updatedAt;

  /// Product lookup data (filled downstream by catalog enrichment).
  final Map<String, dynamic> catalogData;

  /// Decoded EPC fields + RFID read metadata (rssi, antenna, etc.).
  final Map<String, dynamic> tagData;

  /// Zone name for display and filtering.
  final String? zoneName;

  const Tag({
    required this.uid,
    required this.barcode,
    required this.tagType,
    this.countId,
    this.zoneId,
    this.batchId,
    this.userId,
    required this.readTime,
    this.updatedAt,
    this.catalogData = const {},
    this.tagData = const {},
    this.zoneName,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      uid: json['uid'] as String,
      barcode: json['barcode'] as String? ?? '',
      tagType: TagType.fromWire(json['tag_type'] as String?),
      countId: json['count_id'] as int?,
      zoneId: json['zone_id'] as int?,
      batchId: json['batch_id'] as String?,
      userId: json['user_id'] as int?,
      readTime: json['read_time'] != null
          ? DateTime.parse(json['read_time'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      catalogData: (json['catalog_data'] as Map?)?.cast<String, dynamic>() ??
          const {},
      tagData: (json['tag_data'] as Map?)?.cast<String, dynamic>() ?? const {},
      zoneName: json['zone_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'barcode': barcode,
      'tag_type': tagType.wireValue,
      'count_id': countId,
      'zone_id': zoneId,
      'batch_id': batchId,
      'user_id': userId,
      'read_time': readTime.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
      'catalog_data': catalogData,
      'tag_data': tagData,
      'zone_name': zoneName,
    };
  }

  /// Create a [Tag] from a raw [RfidTag] read, decoding the EPC into a barcode
  /// via the currently-configured [BarcodeConverterFactory] standard.
  ///
  /// Throws if the EPC cannot be decoded, so the caller (the decode step) can
  /// skip the read.
  factory Tag.fromRfidTag(
    RfidTag rfidTag, {
    String? batchId,
    int? userId,
  }) {
    final Map<String, dynamic> tagData = {};

    try {
      // The factory automatically uses the current encoding standard.
      final converter = BarcodeConverterFactory.getConverter();
      final barcodeData = converter.decodeFromEpc(rfidTag.epc);

      // Store decoded barcode information.
      tagData['gtin'] = barcodeData.gtin;
      tagData['companyPrefix'] = barcodeData.companyPrefix;
      tagData['itemReference'] = barcodeData.itemReference;
      tagData['serialNumber'] = barcodeData.serialNumber;
      tagData['format'] = barcodeData.format.name;
      tagData['filter'] = barcodeData.filter.name;
      tagData['encodingStandard'] = barcodeData.decodedByStandard ??
          BarcodeConverterFactory.getCurrentStandard().name;

      // Store RFID read metadata (only the fields the kiosk reader reports).
      if (rfidTag.rssi != null) tagData['rssi'] = rfidTag.rssi;
      if (rfidTag.antenna != null) tagData['antenna'] = rfidTag.antenna;
      if (rfidTag.channelIndex != null) {
        tagData['channelIndex'] = rfidTag.channelIndex;
      }
      if (rfidTag.tagSeenCount != null) {
        tagData['tagSeenCount'] = rfidTag.tagSeenCount;
      }

      return Tag(
        uid: rfidTag.epc, // Always use EPC as unique identifier.
        barcode: barcodeData.gtin, // Decoded GTIN or raw EPC.
        tagType: TagType.rfid,
        countId: null,
        zoneId: null,
        batchId: batchId,
        userId: userId,
        readTime: rfidTag.readTime,
        tagData: tagData,
      );
    } catch (error) {
      throw Exception(error);
    }
  }

  /// Creates a copy of this Tag with the given fields replaced.
  /// Use [clearUserId] = true to explicitly set userId to null.
  Tag copyWith({
    String? uid,
    String? barcode,
    TagType? tagType,
    int? countId,
    int? zoneId,
    String? batchId,
    int? userId,
    bool clearUserId = false,
    DateTime? readTime,
    DateTime? updatedAt,
    Map<String, dynamic>? catalogData,
    Map<String, dynamic>? tagData,
    String? zoneName,
  }) {
    return Tag(
      uid: uid ?? this.uid,
      barcode: barcode ?? this.barcode,
      tagType: tagType ?? this.tagType,
      countId: countId ?? this.countId,
      zoneId: zoneId ?? this.zoneId,
      batchId: batchId ?? this.batchId,
      userId: clearUserId ? null : (userId ?? this.userId),
      readTime: readTime ?? this.readTime,
      updatedAt: updatedAt ?? this.updatedAt,
      catalogData: catalogData ?? this.catalogData,
      tagData: tagData ?? this.tagData,
      zoneName: zoneName ?? this.zoneName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag &&
        other.uid == uid &&
        other.barcode == barcode &&
        other.tagType == tagType &&
        other.countId == countId &&
        other.zoneId == zoneId &&
        other.batchId == batchId &&
        other.userId == userId &&
        other.readTime == readTime &&
        other.zoneName == zoneName &&
        _mapEquals(other.catalogData, catalogData) &&
        _mapEquals(other.tagData, tagData);
  }

  @override
  int get hashCode {
    return Object.hash(
      uid,
      barcode,
      tagType,
      countId,
      zoneId,
      batchId,
      userId,
      readTime,
      zoneName,
      Object.hashAllUnordered(
          catalogData.entries.map((e) => Object.hash(e.key, e.value))),
      Object.hashAllUnordered(
          tagData.entries.map((e) => Object.hash(e.key, e.value))),
    );
  }

  bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'Tag(uid: $uid, barcode: $barcode, type: ${tagType.wireValue})';
}
