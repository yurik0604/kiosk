import 'package:objectbox/objectbox.dart';

@Entity()
class Product {
  @Id()
  int id;

  @Index()
  @Unique()
  String rfidTag;

  @Index()
  String sku;

  String name;
  String brand;
  String description;
  String category;
  String subCategory;
  String gender;
  String size;
  String color;
  String colorHex;
  String material;
  String careInstructions;
  String origin;
  String season;
  double priceCents;
  double originalPriceCents;
  String imageUrl;
  int stockQty;

  Product({
    this.id = 0,
    required this.rfidTag,
    required this.sku,
    required this.name,
    required this.brand,
    required this.description,
    required this.category,
    this.subCategory = '',
    this.gender = 'Unisex',
    required this.size,
    required this.color,
    this.colorHex = '#000000',
    required this.material,
    this.careInstructions = '',
    this.origin = '',
    this.season = '',
    required this.priceCents,
    this.originalPriceCents = 0,
    this.imageUrl = '',
    this.stockQty = 0,
  });

  double get price => priceCents / 100.0;
  double get originalPrice => originalPriceCents / 100.0;
  bool get isOnSale => originalPriceCents > priceCents && originalPriceCents > 0;
  double get discountPct =>
      isOnSale ? ((originalPriceCents - priceCents) / originalPriceCents) * 100 : 0;
}
