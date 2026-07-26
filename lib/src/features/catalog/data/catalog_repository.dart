import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../objectbox.g.dart';
import '../../../core/database/object_box.dart';
import '../domain/catalog_item.dart';

final objectBoxProvider = Provider<ObjectBox>((ref) {
  throw UnimplementedError('ObjectBox must be initialized in main()');
});

/// Model-code prefix shared by every shopping-bag catalog entry. Anything in
/// the synced catalog whose `model` starts with this prefix is treated as a bag
/// by the session UI (counted toward `bagCount`, listed in the bag picker).
const String shoppingBagModelPrefix = 'BAG-';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(objectBoxProvider));
});

class CatalogRepository {
  CatalogRepository(this._box);

  final ObjectBox _box;

  CatalogItem? findByBarcode(String barcode) {
    final query =
        _box.catalogItems.query(CatalogItem_.barcode.equals(barcode)).build();
    try {
      return query.findFirst();
    } finally {
      query.close();
    }
  }

  List<CatalogItem> all() => _box.catalogItems.getAll();

  /// Whether a catalog item is a shopping bag (by `model` prefix).
  static bool isBag(CatalogItem item) =>
      item.model.startsWith(shoppingBagModelPrefix);

  /// All shopping-bag items from the synced catalog, ordered by barcode for a
  /// stable presentation in the bag picker.
  List<CatalogItem> shoppingBags() {
    final query = _box.catalogItems
        .query(CatalogItem_.model.startsWith(shoppingBagModelPrefix))
        .order(CatalogItem_.barcode)
        .build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  /// Picks a random product for the simulate-scan action. Shopping bags are
  /// excluded — they're an intentional customer choice made via the bag picker,
  /// not something a simulated tag scan should ever add. All catalog items are
  /// treated as available (the catalog carries no stock quantity).
  CatalogItem? randomAvailable() {
    final list = all().where((p) => !isBag(p)).toList();
    if (list.isEmpty) return null;
    list.shuffle();
    return list.first;
  }
}
