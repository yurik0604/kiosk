/// Encoding standard for RFID tags.
enum EncodingStandard {
  gs1,
  lululemon,
  xcode;

  String get displayName {
    switch (this) {
      case EncodingStandard.gs1:
        return 'GS1';
      case EncodingStandard.lululemon:
        return 'Lululemon';
      case EncodingStandard.xcode:
        return 'XCode';
    }
  }

  String toJson() {
    switch (this) {
      case EncodingStandard.gs1:
        return 'GS1';
      case EncodingStandard.lululemon:
        return 'Lululemon';
      case EncodingStandard.xcode:
        return 'XCode';
    }
  }

  static EncodingStandard fromJson(String? value) {
    switch (value?.toLowerCase()) {
      case 'lululemon':
        return EncodingStandard.lululemon;
      case 'xcode':
        return EncodingStandard.xcode;
      case 'gs1':
      default:
        return EncodingStandard.gs1;
    }
  }
}

/// The group's `group_settings` object.
class GroupSettings {
  final List<String> barcodeStandards;
  final List<String> customerPrefixes;
  final int prefixLength;
  final List<String> displayCatalogData;
  final List<String> displayCatalogDataOpt;
  final String tagAccessPassword;
  final bool useSmartZones;
  final EncodingStandard encodingStandard;
  final int customerXcodePrefix;

  /// Stored nullable internally to tolerate old serialized data missing it.
  final String? _currencySymbol;

  /// Currency symbol for price display, defaulting to ₪ when unset.
  String get currencySymbol => _currencySymbol ?? '₪';

  const GroupSettings({
    required this.barcodeStandards,
    required this.customerPrefixes,
    required this.prefixLength,
    required this.displayCatalogData,
    required this.displayCatalogDataOpt,
    required this.tagAccessPassword,
    required this.useSmartZones,
    required this.encodingStandard,
    required this.customerXcodePrefix,
    String? currencySymbol = '₪',
  }) : _currencySymbol = currencySymbol;

  factory GroupSettings.fromJson(Map<String, dynamic> json) {
    List<String> strList(dynamic value) => (value as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();

    return GroupSettings(
      barcodeStandards: strList(json['barcode_standards']),
      customerPrefixes: strList(json['customer_prefixes']),
      prefixLength: json['prefix_length'] as int? ?? 0,
      displayCatalogData: strList(json['display_catalog_data']),
      displayCatalogDataOpt: strList(json['display_catalog_data_opt']),
      tagAccessPassword: json['tag_access_password'] as String? ?? '',
      useSmartZones: json['use_smart_zones'] as bool? ?? false,
      encodingStandard:
          EncodingStandard.fromJson(json['encoding_standard'] as String?),
      customerXcodePrefix:
          int.tryParse(json['customer_xcode_prefix']?.toString() ?? '') ?? 0,
      currencySymbol: json['currency_symbol'] as String? ?? '₪',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barcode_standards': barcodeStandards,
      'customer_prefixes': customerPrefixes,
      'prefix_length': prefixLength,
      'display_catalog_data': displayCatalogData,
      'display_catalog_data_opt': displayCatalogDataOpt,
      'tag_access_password': tagAccessPassword,
      'use_smart_zones': useSmartZones,
      'encoding_standard': encodingStandard.toJson(),
      'customer_xcode_prefix': customerXcodePrefix.toString(),
      'currency_symbol': currencySymbol,
    };
  }

  GroupSettings copyWith({
    List<String>? barcodeStandards,
    List<String>? customerPrefixes,
    int? prefixLength,
    List<String>? displayCatalogData,
    List<String>? displayCatalogDataOpt,
    String? tagAccessPassword,
    bool? useSmartZones,
    EncodingStandard? encodingStandard,
    int? customerXcodePrefix,
    String? currencySymbol,
  }) {
    return GroupSettings(
      barcodeStandards: barcodeStandards ?? this.barcodeStandards,
      customerPrefixes: customerPrefixes ?? this.customerPrefixes,
      prefixLength: prefixLength ?? this.prefixLength,
      displayCatalogData: displayCatalogData ?? this.displayCatalogData,
      displayCatalogDataOpt:
          displayCatalogDataOpt ?? this.displayCatalogDataOpt,
      tagAccessPassword: tagAccessPassword ?? this.tagAccessPassword,
      useSmartZones: useSmartZones ?? this.useSmartZones,
      encodingStandard: encodingStandard ?? this.encodingStandard,
      customerXcodePrefix: customerXcodePrefix ?? this.customerXcodePrefix,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupSettings &&
        _listEquals(other.barcodeStandards, barcodeStandards) &&
        _listEquals(other.customerPrefixes, customerPrefixes) &&
        other.prefixLength == prefixLength &&
        _listEquals(other.displayCatalogData, displayCatalogData) &&
        _listEquals(other.displayCatalogDataOpt, displayCatalogDataOpt) &&
        other.tagAccessPassword == tagAccessPassword &&
        other.useSmartZones == useSmartZones &&
        other.encodingStandard == encodingStandard &&
        other.customerXcodePrefix == customerXcodePrefix &&
        other.currencySymbol == currencySymbol;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(barcodeStandards),
        Object.hashAll(customerPrefixes),
        prefixLength,
        Object.hashAll(displayCatalogData),
        Object.hashAll(displayCatalogDataOpt),
        tagAccessPassword,
        useSmartZones,
        encodingStandard,
        customerXcodePrefix,
        currencySymbol,
      );

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
