import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../objectbox.g.dart';
import '../../../core/database/object_box.dart';
import '../domain/product.dart';

final objectBoxProvider = Provider<ObjectBox>((ref) {
  throw UnimplementedError('ObjectBox must be initialized in main()');
});

/// SKU prefix shared by every shopping-bag catalog entry. Anything in the
/// catalog whose SKU starts with this prefix is treated as a bag by the
/// session UI (counted toward `bagCount`, listed in the bag picker modal).
const String shoppingBagSkuPrefix = 'BAG-';

/// Known shopping-bag SKUs in the catalog. The bag picker modal lists them
/// in this order; the first one is the default surfaced on the summary tile
/// when no bags are in the cart yet.
const List<String> shoppingBagSkus = ['BAG-STD-S-001', 'BAG-STD-L-001'];

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(objectBoxProvider));
});

class CatalogRepository {
  CatalogRepository(this._box);

  final ObjectBox _box;

  Product? findByRfidTag(String tag) {
    final query = _box.products.query(Product_.rfidTag.equals(tag)).build();
    try {
      return query.findFirst();
    } finally {
      query.close();
    }
  }

  Product? findBySku(String sku) {
    final query = _box.products.query(Product_.sku.equals(sku)).build();
    try {
      return query.findFirst();
    } finally {
      query.close();
    }
  }

  List<Product> all() => _box.products.getAll();

  /// Picks a random in-stock product for the simulate-scan action. Shopping
  /// bags are excluded — they're an intentional customer choice made via the
  /// bag picker, not something a simulated tag scan should ever add.
  Product? randomAvailable() {
    final list = all()
        .where((p) =>
            p.stockQty > 0 && !p.sku.startsWith(shoppingBagSkuPrefix))
        .toList();
    if (list.isEmpty) return null;
    list.shuffle();
    return list.first;
  }
}
