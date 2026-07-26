/// Minimal nested representation of the kiosk's customer group (`group` on the
/// `Kiosks` swagger response).
///
/// Named `...Ref` to avoid colliding with the richer [Group] domain model
/// (which carries `group_settings`). This is only the id/name/slug the kiosk
/// endpoint nests inline.
class KioskGroupRef {
  const KioskGroupRef({
    required this.id,
    required this.name,
    required this.slug,
  });

  final int id;
  final String name;
  final String slug;

  factory KioskGroupRef.fromJson(Map<String, dynamic> json) {
    return KioskGroupRef(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
      };

  @override
  bool operator ==(Object other) =>
      other is KioskGroupRef &&
      other.id == id &&
      other.name == name &&
      other.slug == slug;

  @override
  int get hashCode => Object.hash(id, name, slug);
}
