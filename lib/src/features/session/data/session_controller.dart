import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/catalog_item.dart';
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
  /// The catalog has no per-item sale concept, so every line is eligible.
  bool isMemberEligible(CartItem item) => memberDiscountPct > 0;

  /// Per-line member savings (0 when no member is attached).
  double memberSavingsFor(CartItem item) => isMemberEligible(item)
      ? item.lineTotal * (memberDiscountPct / 100.0)
      : 0.0;

  /// Per-line price after the member discount.
  double effectivePriceFor(CartItem item) =>
      item.lineTotal - memberSavingsFor(item);

  /// Sum of line prices before the member discount is applied.
  double get subtotalBeforeMemberDiscount =>
      items.fold(0.0, (sum, item) => sum + item.lineTotal);

  /// Absolute amount removed by the member discount on this session.
  double get memberDiscountAmount =>
      items.fold(0.0, (sum, item) => sum + memberSavingsFor(item));

  bool get hasMemberDiscount =>
      memberDiscountPct > 0 && memberDiscountAmount > 0.005;

  /// Final amount the customer pays (post-member-discount).
  double get total => subtotalBeforeMemberDiscount - memberDiscountAmount;

  double get savings => memberDiscountAmount;
  bool get hasSavings => savings > 0.005;
  bool get isEmpty => items.isEmpty;

  /// Whether a given catalog item is a shopping bag. Recognized by `model`
  /// prefix so the picker auto-discovers new bag variants from the synced
  /// catalog without needing UI code changes.
  static bool isBag(CatalogItem item) => CatalogRepository.isBag(item);

  /// Total number of shopping-bag line items currently in the cart, across
  /// all variants.
  int get bagCount => items.where((i) => isBag(i.item)).length;

  /// Number of bag line items in the cart for a specific variant barcode.
  int countOfBagBarcode(String barcode) =>
      items.where((i) => i.item.barcode == barcode).length;

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

  /// Maps a physical tag's EPC to the cart line it created, so repeat reads of
  /// the same tag (which the reader emits many times per second while the tag
  /// is in the field) don't create duplicate lines. Cleared on [reset] and
  /// pruned when the corresponding line is removed.
  final Map<String, String> _epcToLineId = {};

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

  void addProduct(CatalogItem item) {
    _seq += 1;
    final lineId =
        '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-$_seq';
    state = state.copyWith(
      items: [...state.items, CartItem(lineId: lineId, item: item)],
    );
  }

  /// Adds a catalog [item] scanned from an RFID tag identified by [epc].
  ///
  /// Idempotent per EPC: while a given physical tag stays in the reader's
  /// field it is reported repeatedly, but only the first read creates a line.
  /// If the customer later removes that line, [removeItem] drops the EPC
  /// mapping, so a subsequent read of the still-present tag re-adds it.
  void addByEpc(String epc, CatalogItem item) {
    if (_epcToLineId.containsKey(epc)) return; // already in cart — dedup.

    _seq += 1;
    final lineId =
        '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-$_seq';
    _epcToLineId[epc] = lineId;
    state = state.copyWith(
      items: [...state.items, CartItem(lineId: lineId, item: item, epc: epc)],
    );
  }

  void removeItem(String lineId) {
    // Keep the EPC→line map in sync: if this line came from a tag, drop its
    // mapping so the tag can re-add on the next read.
    _epcToLineId.removeWhere((_, id) => id == lineId);
    state = state.copyWith(
      items: state.items.where((i) => i.lineId != lineId).toList(),
    );
  }

  void reset() {
    _seq = 0;
    _epcToLineId.clear();
    state = const SessionState();
    ref.read(memberControllerProvider.notifier).clear();
    ref.read(currentShopperProvider.notifier).clear();
  }

  void simulateScan() {
    final item = ref.read(catalogRepositoryProvider).randomAvailable();
    if (item != null) addProduct(item);
  }

  /// Adds [qty] bags of the given variant barcode. No-op if the barcode isn't
  /// found in the catalog (UI degrades safely).
  void addBagByBarcode(String barcode, {int qty = 1}) {
    if (qty <= 0) return;
    final bag = ref.read(catalogRepositoryProvider).findByBarcode(barcode);
    if (bag == null) return;
    for (var i = 0; i < qty; i++) {
      addProduct(bag);
    }
  }

  /// Removes [qty] bag line items of the given variant barcode (most-recently
  /// added first). Stops when no more matching bag lines remain.
  void removeBagByBarcode(String barcode, {int qty = 1}) {
    if (qty <= 0) return;
    var toRemove = qty;
    final next = <CartItem>[];
    // Walk from the end so we drop the most recent matching line first;
    // matches typical "undo last add" intent.
    for (final item in state.items.reversed) {
      if (toRemove > 0 && item.item.barcode == barcode) {
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
