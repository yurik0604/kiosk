import 'catalog_item.dart';

/// UI-facing accessors for the descriptive fields that used to be first-class
/// columns on the old `Product` entity and now live in [CatalogItem.attrs].
///
/// Centralizing the attribute key names here means there is a single place to
/// adjust them once the server's `attrs` shape is confirmed. Every accessor
/// degrades to an empty string when the attribute is absent, so the UI can gate
/// on `isEmpty` exactly as it did before.
extension CatalogItemDisplay on CatalogItem {
  String get brand => attr('brand');
  String get category => attr('category');
  String get subCategory => attr('subCategory');
  String get gender => attr('gender');
  String get size => attr('size');
  String get color => attr('color');
  String get colorHex => attr('colorHex');
  String get material => attr('material');
  String get careInstructions => attr('careInstructions');
  String get origin => attr('origin');
  String get season => attr('season');
}
