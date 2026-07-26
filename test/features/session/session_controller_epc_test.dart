import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk/src/features/catalog/domain/catalog_item.dart';
import 'package:kiosk/src/features/session/data/session_controller.dart';

/// Tests the EPC-keyed cart operations that back the RFID tag→cart bridge.
/// The critical property: one physical tag (unique EPC), read many times,
/// produces exactly one cart line.
void main() {
  late ProviderContainer container;
  late SessionController controller;

  setUp(() {
    container = ProviderContainer();
    controller = container.read(sessionControllerProvider.notifier);
  });

  tearDown(() => container.dispose());

  CatalogItem item(String barcode, {double price = 10}) =>
      CatalogItem(barcode: barcode, name: 'Item $barcode', price: price);

  SessionState state() => container.read(sessionControllerProvider);

  test('addByEpc adds a single line the first time an EPC is seen', () {
    controller.addByEpc('EPC-A', item('111'));

    expect(state().items, hasLength(1));
    expect(state().items.single.epc, 'EPC-A');
    expect(state().items.single.item.barcode, '111');
  });

  test('repeat reads of the same EPC do not create duplicate lines', () {
    for (var i = 0; i < 50; i++) {
      controller.addByEpc('EPC-A', item('111'));
    }
    expect(state().items, hasLength(1));
  });

  test('different EPCs create distinct lines even for the same barcode', () {
    controller.addByEpc('EPC-A', item('111'));
    controller.addByEpc('EPC-B', item('111'));

    expect(state().items, hasLength(2));
    expect(state().items.map((i) => i.epc), containsAll(['EPC-A', 'EPC-B']));
  });

  test('removing a tag line lets the same EPC re-add on the next read', () {
    controller.addByEpc('EPC-A', item('111'));
    final lineId = state().items.single.lineId;

    controller.removeItem(lineId);
    expect(state().items, isEmpty);

    // Tag still on the antenna → next read re-adds it.
    controller.addByEpc('EPC-A', item('111'));
    expect(state().items, hasLength(1));
  });

  test('reset clears the EPC map so a new customer starts clean', () {
    controller.addByEpc('EPC-A', item('111'));
    controller.reset();
    expect(state().items, isEmpty);

    // Same EPC after reset is treated as new (not deduped against prior session).
    controller.addByEpc('EPC-A', item('111'));
    expect(state().items, hasLength(1));
  });

  test('manual addProduct lines carry no EPC and are independent', () {
    controller.addProduct(item('999'));
    controller.addByEpc('EPC-A', item('111'));

    expect(state().items, hasLength(2));
    final manual = state().items.firstWhere((i) => i.item.barcode == '999');
    expect(manual.epc, isNull);
  });
}
