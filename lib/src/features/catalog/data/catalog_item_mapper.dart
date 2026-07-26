import 'dart:convert';

import '../../../../objectbox.g.dart';
import '../domain/catalog_item.dart';

/// Convert a JSON-decoded map (one JSONL line) to a [CatalogItem].
///
/// Must be a top-level function so it can run inside ObjectBox isolate
/// transactions. Coerces values defensively with safe defaults.
CatalogItem mapToCatalogItem(Map<String, dynamic> rowMap) {
  final attrs = <String, String>{};

  // 'attrs' may be a JSON string or a Map.
  final rawAttrs = rowMap['attrs'];
  if (rawAttrs is String && rawAttrs.isNotEmpty && rawAttrs != '{}') {
    try {
      final decoded = jsonDecode(rawAttrs);
      if (decoded is Map) {
        for (final entry in decoded.entries) {
          if (entry.value != null && entry.value.toString().isNotEmpty) {
            attrs[entry.key.toString()] = entry.value.toString();
          }
        }
      }
    } catch (_) {
      // Ignore malformed JSON.
    }
  } else if (rawAttrs is Map) {
    for (final entry in rawAttrs.entries) {
      if (entry.value != null && entry.value.toString().isNotEmpty) {
        attrs[entry.key.toString()] = entry.value.toString();
      }
    }
  }

  // Flattened `attrs_*` columns (e.g. {"attrs_color": "red"}).
  for (final key in rowMap.keys) {
    if (key.startsWith('attrs_') && rowMap[key] != null) {
      attrs[key.substring(6)] = rowMap[key].toString();
    }
  }

  return CatalogItem.create(
    catalogId: _toInt(rowMap['catalogId'] ?? rowMap['catalog_id']),
    barcode: rowMap['barcode']?.toString() ?? '',
    barcode1: rowMap['barcode_1']?.toString() ?? '',
    barcode2: rowMap['barcode_2']?.toString() ?? '',
    barcode3: rowMap['barcode_3']?.toString() ?? '',
    name: rowMap['name']?.toString() ?? '',
    model: rowMap['model']?.toString() ?? '',
    modelName: rowMap['model_name']?.toString() ?? '',
    description: rowMap['description']?.toString() ?? '',
    price: _toDouble(rowMap['price']),
    imgUrl: rowMap['img_url']?.toString() ?? '',
    lastUpdateDate: _toDateTime(rowMap['lastupdatedate']) ?? DateTime.now(),
    attrs: attrs,
  );
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0.0;
  return 0.0;
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value) ??
        DateTime.tryParse(value.replaceAll('/', '-'));
  }
  return null;
}

/// Batch-insert callback for an ObjectBox isolate transaction.
/// Returns the number of items inserted.
int batchInsertCallback(Store store, List<Map<String, dynamic>> batchData) {
  final box = store.box<CatalogItem>();
  box.putMany(batchData.map(mapToCatalogItem).toList());
  return batchData.length;
}

/// Clear all catalog items. Runs in an ObjectBox isolate transaction.
/// Returns the number of items removed.
int clearDatabaseCallback(Store store, void _) {
  final box = store.box<CatalogItem>();
  final count = box.count();
  box.removeAll();
  return count;
}
