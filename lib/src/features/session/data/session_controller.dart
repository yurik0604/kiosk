import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/product.dart';
import '../../member/data/current_shopper_controller.dart';
import '../../member/data/member_controller.dart';
import '../domain/cart_item.dart';

class SessionState {
  const SessionState({
    this.items = const [],
    this.memberDiscountPct = 0,
  });

  final List<CartItem> items;

  /// Flat percentage discount granted by an attached club member. 0 if no
  /// member is attached. Re-applied to every line at totalling time.
  final double memberDiscountPct;

  int get itemCount => items.length;

  /// Whether the member discount can be applied to this specific line.
  /// Items already on sale are excluded so that promotions don't stack.
  bool isMemberEligible(CartItem item) =>
      memberDiscountPct > 0 && !item.product.isOnSale;

  /// Per-line member savings (0 when the item is on sale or no member).
  double memberSavingsFor(CartItem item) => isMemberEligible(item)
      ? item.lineTotal * (memberDiscountPct / 100.0)
      : 0.0;

  /// Per-line price after the member discount (catalog price when the
  /// member discount doesn't apply to this item).
  double effectivePriceFor(CartItem item) =>
      item.lineTotal - memberSavingsFor(item);

  /// Sum of line prices before the member discount is applied.
  double get subtotalBeforeMemberDiscount =>
      items.fold(0.0, (sum, item) => sum + item.lineTotal);

  /// Absolute amount removed by the member discount on this session.
  /// Computed per-item so sale items are skipped.
  double get memberDiscountAmount =>
      items.fold(0.0, (sum, item) => sum + memberSavingsFor(item));

  bool get hasMemberDiscount =>
      memberDiscountPct > 0 && memberDiscountAmount > 0.005;

  /// Amount saved purely from in-store sale prices (catalog vs. sale price),
  /// summed across every line. Independent of the member discount.
  double get saleDiscountAmount =>
      (originalTotal - subtotalBeforeMemberDiscount).clamp(0.0, double.infinity);

  bool get hasSaleDiscount => saleDiscountAmount > 0.005;

  /// Final amount the customer pays (post-sale + post-member-discount).
  double get total =>
      subtotalBeforeMemberDiscount - memberDiscountAmount;

  /// Sum of catalog (pre-sale) prices, used as the "before" reference for
  /// the combined savings line.
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

  /// Whether a given product is a shopping-bag SKU. Recognized by SKU
  /// prefix so the picker auto-discovers new bag variants from the catalog
  /// without needing UI code changes.
  static bool isBag(Product product) =>
      product.sku.startsWith(shoppingBagSkuPrefix);

  /// Total number of shopping-bag line items currently in the cart, across
  /// all variants.
  int get bagCount => items.where((i) => isBag(i.product)).length;

  /// Number of bag line items in the cart for a specific variant SKU.
  int countOfBagSku(String sku) =>
      items.where((i) => i.product.sku == sku).length;

  SessionState copyWith({
    List<CartItem>? items,
    double? memberDiscountPct,
  }) =>
      SessionState(
        items: items ?? this.items,
        memberDiscountPct: memberDiscountPct ?? this.memberDiscountPct,
      );
}

class SessionController extends Notifier<SessionState> {
  int _seq = 0;

  @override
  SessionState build() {
    // Mirror the attached member's flat discount into the session totals.
    // Listening here (rather than reading on every getter) keeps the state
    // immutable and ensures dependent UI rebuilds when the member changes.
    ref.listen(memberControllerProvider, (_, next) {
      final pct = next.member?.discountPct ?? 0;
      if (pct != state.memberDiscountPct) {
        state = state.copyWith(memberDiscountPct: pct);
      }
      // Mirror the attached member into the session-scoped current shopper so
      // downstream flows (e.g. receipt delivery) can read member + phone
      // globally without depending on the member lookup UI.
      final member = next.member;
      if (member != null) {
        ref.read(currentShopperProvider.notifier).setMember(member);
      }
    });
    final initialPct = ref.read(memberControllerProvider).member?.discountPct ?? 0;
    return SessionState(memberDiscountPct: initialPct);
  }

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
    ref.read(memberControllerProvider.notifier).clear();
    ref.read(currentShopperProvider.notifier).clear();
  }

  void simulateScan() {
    final product = ref.read(catalogRepositoryProvider).randomAvailable();
    if (product != null) addProduct(product);
  }

  /// Adds [qty] bags of the given variant SKU. No-op if the SKU isn't
  /// found in the catalog (UI degrades safely).
  void addBagBySku(String sku, {int qty = 1}) {
    if (qty <= 0) return;
    final bag = ref.read(catalogRepositoryProvider).findBySku(sku);
    if (bag == null) return;
    for (var i = 0; i < qty; i++) {
      addProduct(bag);
    }
  }

  /// Removes [qty] bag line items of the given variant SKU (most-recently
  /// added first). Stops when no more matching bag lines remain.
  void removeBagBySku(String sku, {int qty = 1}) {
    if (qty <= 0) return;
    var toRemove = qty;
    final next = <CartItem>[];
    // Walk from the end so we drop the most recent matching line first;
    // matches typical "undo last add" intent.
    for (final item in state.items.reversed) {
      if (toRemove > 0 && item.product.sku == sku) {
        toRemove -= 1;
        continue;
      }
      next.add(item);
    }
    state = state.copyWith(items: next.reversed.toList());
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
