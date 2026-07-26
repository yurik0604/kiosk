/// The catalog `config` object.
///
/// Shape (all optional):
/// ```json
/// { "validity_days": 7, "img_url_template": null, "update_stocks_on_change": false }
/// ```
class CatalogConfig {
  /// How many days a local catalog stays "valid" before it's considered
  /// outdated. Null when not specified; `0` means "never expires".
  final int? validityDays;

  /// Optional URL template for building item image URLs.
  final String? imgUrlTemplate;

  /// Whether stock is updated when the catalog changes.
  final bool? updateStocksOnChange;

  const CatalogConfig({
    this.validityDays,
    this.imgUrlTemplate,
    this.updateStocksOnChange,
  });

  factory CatalogConfig.fromJson(Map<String, dynamic> json) {
    int? optInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return CatalogConfig(
      validityDays: optInt(json['validity_days']),
      imgUrlTemplate: json['img_url_template'] as String?,
      updateStocksOnChange: json['update_stocks_on_change'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'validity_days': validityDays,
      'img_url_template': imgUrlTemplate,
      'update_stocks_on_change': updateStocksOnChange,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CatalogConfig &&
        other.validityDays == validityDays &&
        other.imgUrlTemplate == imgUrlTemplate &&
        other.updateStocksOnChange == updateStocksOnChange;
  }

  @override
  int get hashCode =>
      Object.hash(validityDays, imgUrlTemplate, updateStocksOnChange);
}

/// Metadata about the catalog file on the server. The [etag] is the stable
/// per-file-version validator used to skip re-downloading an unchanged catalog.
class CatalogFileInfo {
  final String etag;
  final String filePath;
  final int fileSize;

  const CatalogFileInfo({
    required this.etag,
    required this.filePath,
    required this.fileSize,
  });

  factory CatalogFileInfo.fromJson(Map<String, dynamic> json) {
    return CatalogFileInfo(
      etag: json['etag'] as String? ?? '',
      filePath: json['file_path'] as String? ?? '',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'etag': etag,
      'file_path': filePath,
      'file_size': fileSize,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CatalogFileInfo &&
        other.etag == etag &&
        other.filePath == filePath &&
        other.fileSize == fileSize;
  }

  @override
  int get hashCode => Object.hash(etag, filePath, fileSize);
}

/// Server-side catalog metadata for a group. Fetched from
/// `GET v1/groups/{id}/catalog/`. The [updatedAt] timestamp and
/// [fileInfo].etag together drive the "should we sync?" decision.
class Catalog {
  final int id;
  final int tenantId;
  final int groupId;
  final String groupName;
  final CatalogFileInfo? fileInfo;
  final int totalItems;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CatalogConfig? config;

  const Catalog({
    required this.id,
    required this.tenantId,
    required this.groupId,
    required this.groupName,
    this.fileInfo,
    required this.totalItems,
    required this.createdAt,
    required this.updatedAt,
    this.config,
  });

  /// Whether this catalog has items available to sync.
  bool get hasItems => totalItems > 0 && fileInfo != null;

  /// Catalog validity window in days, from `config.validity_days`. Null when
  /// unspecified; `0` means "never expires".
  int? get validityDays => config?.validityDays;

  factory Catalog.fromJson(Map<String, dynamic> json) {
    int safeInt(dynamic value, String fieldName) {
      if (value == null) {
        throw ArgumentError('Required field "$fieldName" is null in Catalog JSON');
      }
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
      throw ArgumentError(
          'Field "$fieldName" cannot be converted to int: $value');
    }

    final configJson = json['config'];
    final config = configJson is Map<String, dynamic>
        ? CatalogConfig.fromJson(configJson)
        : null;

    return Catalog(
      id: safeInt(json['id'], 'id'),
      tenantId: safeInt(json['tenant_id'], 'tenant_id'),
      groupId: safeInt(json['group_id'], 'group_id'),
      groupName: json['group_name'] as String? ?? '',
      fileInfo: json['file_info'] != null
          ? CatalogFileInfo.fromJson(json['file_info'] as Map<String, dynamic>)
          : null,
      totalItems: safeInt(json['total_items'], 'total_items'),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      config: config,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'group_id': groupId,
      'group_name': groupName,
      'file_info': fileInfo?.toJson(),
      'total_items': totalItems,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (config != null) 'config': config!.toJson(),
    };
  }

  Catalog copyWith({
    int? id,
    int? tenantId,
    int? groupId,
    String? groupName,
    CatalogFileInfo? fileInfo,
    int? totalItems,
    DateTime? createdAt,
    DateTime? updatedAt,
    CatalogConfig? config,
  }) {
    return Catalog(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      fileInfo: fileInfo ?? this.fileInfo,
      totalItems: totalItems ?? this.totalItems,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      config: config ?? this.config,
    );
  }

  @override
  String toString() =>
      'Catalog{id: $id, groupId: $groupId, totalItems: $totalItems, updatedAt: $updatedAt}';
}
