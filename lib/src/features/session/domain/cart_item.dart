import '../../catalog/domain/catalog_item.dart';

class CartItem {
  CartItem({required this.lineId, required this.item, this.epc});

  final String lineId;
  final CatalogItem item;

  /// Source RFID EPC when this line was added by a tag read; `null` for lines
  /// added manually (simulate-scan, bag picker). Lets the session controller
  /// keep its EPC→line map in sync when the line is removed.
  final String? epc;

  double get lineTotal => item.price;
}
