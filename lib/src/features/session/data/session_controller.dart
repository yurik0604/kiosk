import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/product.dart';
import '../domain/cart_item.dart';

class SessionState {
  const SessionState({this.items = const []});

  final List<CartItem> items;

  int get itemCount => items.length;
  double get total => items.fold(0.0, (sum, item) => sum + item.lineTotal);
  double get originalTotal => items.fold(
        0.0,
        (sum, item) => sum +
            (item.product.isOnSale
                ? item.product.originalPrice
                : item.product.price),
      );
  double get savings => (originalTotal - total).clamp(0.0, double.infinity);
  bool get hasSavings => savings > 0.005;
  bool get isEmpty => items.isEmpty;

  SessionState copyWith({List<CartItem>? items}) =>
      SessionState(items: items ?? this.items);
}

class SessionController extends Notifier<SessionState> {
  int _seq = 0;

  @override
  SessionState build() => const SessionState();

  void addProduct(Product product) {
    _seq += 1;
    final lineId =
        '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-$_seq';
    state = state.copyWith(
      items: [...state.items, CartItem(lineId: lineId, product: product)],
    );
  }

  void removeItem(String lineId) {
    state = state.copyWith(
      items: state.items.where((i) => i.lineId != lineId).toList(),
    );
  }

  void reset() {
    _seq = 0;
    state = const SessionState();
  }

  void simulateScan() {
    final product = ref.read(catalogRepositoryProvider).randomAvailable();
    if (product != null) addProduct(product);
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
