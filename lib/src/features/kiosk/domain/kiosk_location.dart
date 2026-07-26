/// Minimal nested representation of the kiosk's location (`location` on the
/// `Kiosks` swagger response).
class KioskLocation {
  const KioskLocation({
    required this.id,
    required this.name,
    required this.label,
  });

  final int id;
  final String name;
  final String label;

  factory KioskLocation.fromJson(Map<String, dynamic> json) {
    return KioskLocation(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'label': label,
      };

  @override
  bool operator ==(Object other) =>
      other is KioskLocation &&
      other.id == id &&
      other.name == name &&
      other.label == label;

  @override
  int get hashCode => Object.hash(id, name, label);
}
