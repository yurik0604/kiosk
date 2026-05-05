import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../objectbox.g.dart';
import '../../features/catalog/domain/product.dart';

class ObjectBox {
  ObjectBox._(this.store);

  static const _seedVersion = 3;

  final Store store;
  late final Box<Product> products = store.box<Product>();

  static Future<ObjectBox> create() async {
    final docs = await getApplicationDocumentsDirectory();
    final dbDir = Directory('${docs.path}/objectbox');
    final stamp = File('${docs.path}/objectbox.version');

    final stampValue = stamp.existsSync() ? stamp.readAsStringSync() : '';
    if (stampValue != '$_seedVersion' && dbDir.existsSync()) {
      dbDir.deleteSync(recursive: true);
    }

    final store = await openStore(directory: dbDir.path);
    final ob = ObjectBox._(store);
    ob._seedIfEmpty();
    stamp.writeAsStringSync('$_seedVersion');
    return ob;
  }

  void _seedIfEmpty() {
    if (products.count() > 0) return;
    products.putMany(_seedData);
  }

  static final List<Product> _seedData = [
    Product(
      rfidTag: 'E2000017211000657890ABCD',
      sku: 'AT-DNM-501-IND-32',
      name: 'Tapered Selvedge Jeans',
      brand: 'Atelier North',
      description:
          'Mid-rise tapered jeans crafted from 13 oz Japanese selvedge denim. Hand-finished with copper rivets and a leather patch. Designed to age beautifully with wear.',
      category: 'Apparel',
      subCategory: 'Jeans',
      gender: 'Men',
      size: '32 / 32',
      color: 'Indigo Rinse',
      colorHex: '#1F3A5F',
      material: '100% Cotton, Selvedge',
      careInstructions: 'Cold wash inside out. Hang dry. Iron on reverse.',
      origin: 'Made in Japan',
      season: 'FW26',
      priceCents: 18900,
      originalPriceCents: 0,
      imageUrl:
          'https://images.unsplash.com/photo-1542272604-787c3835535d?w=800&q=80',
      stockQty: 12,
    ),
    Product(
      rfidTag: 'E2000017211000657890BEEF',
      sku: 'MR-TEE-OS-WHT-M',
      name: 'Pima Oversized Tee',
      brand: 'Maison Roux',
      description:
          'Relaxed-fit tee in luxuriously soft Peruvian Pima cotton. Ribbed crew neckline with reinforced shoulder seams. A modern wardrobe essential.',
      category: 'Apparel',
      subCategory: 'T-Shirts',
      gender: 'Unisex',
      size: 'M',
      color: 'Off White',
      colorHex: '#F4EFE6',
      material: '100% Pima Cotton',
      careInstructions: 'Machine wash cold. Tumble dry low. Do not bleach.',
      origin: 'Made in Portugal',
      season: 'SS26',
      priceCents: 4500,
      originalPriceCents: 6500,
      imageUrl:
          'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800&q=80',
      stockQty: 28,
    ),
    Product(
      rfidTag: 'E2000017211000657890CAFE',
      sku: 'LV-DRS-MID-BLK-S',
      name: 'Bias-Cut Slip Dress',
      brand: 'Lune Vert',
      description:
          'Fluid bias-cut midi dress in liquid satin with adjustable spaghetti straps and a cowl neckline. Effortless evening elegance.',
      category: 'Apparel',
      subCategory: 'Dresses',
      gender: 'Women',
      size: 'S',
      color: 'Onyx Black',
      colorHex: '#0E0E10',
      material: 'Triacetate Satin',
      careInstructions: 'Dry clean only. Steam to remove wrinkles.',
      origin: 'Made in Italy',
      season: 'FW26',
      priceCents: 24500,
      originalPriceCents: 0,
      imageUrl:
          'https://images.unsplash.com/photo-1539008835657-9e8e9680c956?w=800&q=80',
      stockQty: 7,
    ),
    Product(
      rfidTag: 'E2000017211000657890DAD0',
      sku: 'NS-JKT-WL-CAM-L',
      name: 'Wool Overshirt Jacket',
      brand: 'North & State',
      description:
          'Soft-shouldered overshirt in Italian double-faced wool. Patch pockets, horn buttons, and a clean unstructured cut for everyday layering.',
      category: 'Apparel',
      subCategory: 'Jackets',
      gender: 'Men',
      size: 'L',
      color: 'Camel',
      colorHex: '#B58A5A',
      material: '85% Wool, 15% Cashmere',
      careInstructions: 'Dry clean only. Brush after wear. Store on hanger.',
      origin: 'Woven in Biella, Italy',
      season: 'FW26',
      priceCents: 38000,
      originalPriceCents: 0,
      imageUrl:
          'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=800&q=80',
      stockQty: 5,
    ),
    Product(
      rfidTag: 'E2000017211000657890ED1F',
      sku: 'KO-SNK-LO-WHT-42',
      name: 'Court Low Sneakers',
      brand: 'Kōji',
      description:
          'Minimal court silhouette in full-grain Italian leather with a vulcanized rubber sole and tonal stitching. Timeless and quietly luxurious.',
      category: 'Footwear',
      subCategory: 'Sneakers',
      gender: 'Unisex',
      size: 'EU 42',
      color: 'Optic White',
      colorHex: '#FAFAFA',
      material: 'Full-Grain Leather, Rubber Sole',
      careInstructions: 'Wipe with damp cloth. Use leather conditioner monthly.',
      origin: 'Made in Italy',
      season: 'SS26',
      priceCents: 22000,
      originalPriceCents: 0,
      imageUrl:
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&q=80',
      stockQty: 14,
    ),
    Product(
      rfidTag: 'E2000017211000657890F00D',
      sku: 'AS-SCF-CSH-BRG-OS',
      name: 'Cashmere Fringe Scarf',
      brand: 'Aria Studio',
      description:
          'Generously sized scarf woven from pure Mongolian cashmere with hand-knotted fringe. Lightweight warmth with a refined drape.',
      category: 'Accessories',
      subCategory: 'Scarves',
      gender: 'Unisex',
      size: 'One Size · 200×70 cm',
      color: 'Burgundy',
      colorHex: '#6B1F2A',
      material: '100% Cashmere',
      careInstructions: 'Hand wash cold or dry clean. Lay flat to dry.',
      origin: 'Spun in Inner Mongolia',
      season: 'FW26',
      priceCents: 16500,
      originalPriceCents: 22000,
      imageUrl:
          'https://images.unsplash.com/photo-1601244005535-a48d21d951ac?w=800&q=80',
      stockQty: 9,
    ),
  ];
}
