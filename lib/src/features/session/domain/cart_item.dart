import '../../catalog/domain/catalog_item.dart';

class CartItem {
  CartItem({required this.lineId, required this.item});

  final String lineId;
  final CatalogItem item;

  double get lineTotal => item.price;
}
