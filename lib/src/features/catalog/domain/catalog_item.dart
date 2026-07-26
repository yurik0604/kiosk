import 'dart:convert';

import 'package:objectbox/objectbox.dart';

/// The synced catalog entity — one row per sellable item.
///
/// Populated by the catalog sync pipeline (see `catalog/data/catalog_service.dart`)
/// from a gzipped JSONL file the server produces. Descriptive attributes that
/// don't have a first-class column (brand, color, size, …) live in the free-form
/// [attrs] map, serialized as [attrsJson] because ObjectBox has no Map support.
@Entity()
class CatalogItem {
  @Id()
  int id;

  /// Server-side catalog id this item belongs to (not indexed).
  int catalogId;

  @Index()
  String barcode;

  @Index()
  String barcode1;

  @Index()
  String barcode2;

  @Index()
  String barcode3;

  @Index()
  String name;

  /// Style/model code shared by all variants of a product. Indexed so the
  /// catalog can be grouped by model (mirrors the server-side `model` index).
  /// Also used to recognise shopping bags (model prefixed `BAG-`).
  @Index()
  String model;

  /// Human-readable model/style name (server field `model_name`).
  String modelName;

  String description;

  double price;

  @Property(type: PropertyType.date)
  DateTime lastUpdateDate;

  String imgUrl;

  /// Free-form attributes as a JSON string (ObjectBox doesn't support Map).
  String attrsJson;

  CatalogItem({
    this.id = 0,
    this.catalogId = 0,
    this.barcode = '',
    this.barcode1 = '',
    this.barcode2 = '',
    this.barcode3 = '',
    this.name = '',
    this.model = '',
    this.modelName = '',
    this.description = '',
    this.price = 0.0,
    this.imgUrl = '',
    DateTime? lastUpdateDate,
    this.attrsJson = '{}',
  }) : lastUpdateDate = lastUpdateDate ?? DateTime.now();

  factory CatalogItem.create({
    int catalogId = 0,
    required String barcode,
    required String barcode1,
    required String barcode2,
    required String barcode3,
    required String name,
    String model = '',
    String modelName = '',
    required String description,
    required double price,
    required String imgUrl,
    required DateTime lastUpdateDate,
    required Map<String, String> attrs,
  }) {
    return CatalogItem(
      catalogId: catalogId,
      barcode: barcode,
      barcode1: barcode1,
      barcode2: barcode2,
      barcode3: barcode3,
      name: name,
      model: model,
      modelName: modelName,
      description: description,
      price: price,
      imgUrl: imgUrl,
      lastUpdateDate: lastUpdateDate,
      attrsJson: jsonEncode(attrs),
    );
  }

  /// Decoded free-form attributes. Not persisted directly — derived from
  /// [attrsJson].
  @Transient()
  Map<String, String> get attrs {
    try {
      final decoded = jsonDecode(attrsJson) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      return <String, String>{};
    }
  }

  set attrs(Map<String, String> value) {
    attrsJson = jsonEncode(value);
  }

  /// Convenience accessor for a single attribute, empty string when absent.
  /// The UI reads descriptive fields (brand, color, size, …) through this.
  @Transient()
  String attr(String key) => attrs[key] ?? '';

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem.create(
      catalogId: json['catalogId'] as int? ?? 0,
      barcode: json['barcode'] as String? ?? '',
      barcode1: json['barcode_1'] as String? ?? '',
      barcode2: json['barcode_2'] as String? ?? '',
      barcode3: json['barcode_3'] as String? ?? '',
      name: json['name'] as String? ?? '',
      model: json['model'] as String? ?? '',
      modelName: json['model_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imgUrl: json['img_url'] as String? ?? '',
      lastUpdateDate: json['lastUpdateDate'] != null
          ? DateTime.parse(json['lastUpdateDate'] as String)
          : DateTime.now(),
      attrs: Map<String, String>.from(
        (json['attrs'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'catalogId': catalogId,
      'barcode': barcode,
      'barcode_1': barcode1,
      'barcode_2': barcode2,
      'barcode_3': barcode3,
      'name': name,
      'model': model,
      'model_name': modelName,
      'description': description,
      'price': price,
      'img_url': imgUrl,
      'lastUpdateDate': lastUpdateDate.toIso8601String(),
      'attrs': attrs,
    };
  }

  CatalogItem copyWith({
    int? catalogId,
    String? barcode,
    String? barcode1,
    String? barcode2,
    String? barcode3,
    String? name,
    String? model,
    String? modelName,
    String? description,
    double? price,
    String? imgUrl,
    DateTime? lastUpdateDate,
    Map<String, String>? attrs,
  }) {
    return CatalogItem.create(
      catalogId: catalogId ?? this.catalogId,
      barcode: barcode ?? this.barcode,
      barcode1: barcode1 ?? this.barcode1,
      barcode2: barcode2 ?? this.barcode2,
      barcode3: barcode3 ?? this.barcode3,
      name: name ?? this.name,
      model: model ?? this.model,
      modelName: modelName ?? this.modelName,
      description: description ?? this.description,
      price: price ?? this.price,
      imgUrl: imgUrl ?? this.imgUrl,
      lastUpdateDate: lastUpdateDate ?? this.lastUpdateDate,
      attrs: attrs ?? this.attrs,
    );
  }

  @override
  String toString() =>
      'CatalogItem{id: $id, catalogId: $catalogId, barcode: $barcode, name: $name}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CatalogItem &&
        other.catalogId == catalogId &&
        other.barcode == barcode &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(catalogId, barcode, name);
}
