import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../objectbox.g.dart';
import '../../../core/database/object_box.dart';
import '../domain/product.dart';

final objectBoxProvider = Provider<ObjectBox>((ref) {
  throw UnimplementedError('ObjectBox must be initialized in main()');
});

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

  List<Product> all() => _box.products.getAll();

  Product? randomAvailable() {
    final list = all().where((p) => p.stockQty > 0).toList();
    if (list.isEmpty) return null;
    list.shuffle();
    return list.first;
  }
}
