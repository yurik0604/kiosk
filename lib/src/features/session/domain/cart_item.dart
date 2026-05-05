import '../../catalog/domain/product.dart';

class CartItem {
  CartItem({required this.lineId, required this.product});

  final String lineId;
  final Product product;

  double get lineTotal => product.price;
}
