import 'kiosk_group_ref.dart';
import 'kiosk_location.dart';
import 'kiosk_rfid_config.dart';

/// A kiosk device — the entity this app instance represents on the backend.
///
/// Mirrors the read/detail shape returned by the `Kiosks` swagger endpoint
/// (`GET /v1/kiosks/` and `GET /v1/kiosks/{id}/`). Example response:
///
/// ```json
/// {
///   "id": 3,
///   "name": "kiosk5",
///   "slug": "kiosk5",
///   "description": "Front-entrance self-checkout kiosk",
///   "location": {"id": 5, "name": "Downtown Store", "label": "DT-01"},
///   "group": {"id": 7, "name": "Retail West", "slug": "retail-west"},
///   "access_code": "5555",
///   "catalog_config": {},
///   "rfid_config": {
///     "vendor": "Sensormatic IDX-4000",
///     "ip": "192.168.1.50",
///     "port": 5084,
///     "prevent_duplicates": true,
///     "antennas": [1, 2, 3, 4],
///     "power": [18, 18, 18, 18],
///     "mask": ""
///   },
///   "created_at": "2026-07-26T12:34:56Z"
/// }
/// ```
class Kiosk {
  const Kiosk({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    this.location,
    this.group,
    required this.accessCode,
    required this.catalogConfig,
    required this.rfidConfig,
    this.createdAt,
  });

  /// Kiosk's unique id (backend primary key).
  final int id;

  /// Human-friendly kiosk name (auto-generated as `kiosk<location_id>` when
  /// blank on the backend).
  final String name;

  /// URL-safe unique identifier (unique per tenant).
  final String slug;

  final String description;

  /// Nested location the kiosk is installed at. Null if the backend omits it.
  final KioskLocation? location;

  /// Nested customer group the kiosk belongs to. Null if unassigned.
  final KioskGroupRef? group;

  /// Access code used to unlock the kiosk app (4 to 6 digits).
  final String accessCode;

  /// Catalog configuration blob. Schema is backend-defined (stored as-is), so
  /// it's kept as a raw map.
  final Map<String, dynamic> catalogConfig;

  /// RFID reader configuration for this kiosk.
  final KioskRfidConfig rfidConfig;

  /// Server-side creation timestamp (read-only).
  final DateTime? createdAt;

  int? get groupId => group?.id;
  int? get locationId => location?.id;

  factory Kiosk.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    final group = json['group'];
    return Kiosk(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: location is Map<String, dynamic>
          ? KioskLocation.fromJson(location)
          : null,
      group: group is Map<String, dynamic>
          ? KioskGroupRef.fromJson(group)
          : null,
      accessCode: json['access_code'] as String? ?? '',
      catalogConfig:
          (json['catalog_config'] as Map<String, dynamic>?) ?? const {},
      rfidConfig: KioskRfidConfig.fromJson(
        json['rfid_config'] as Map<String, dynamic>? ?? const {},
      ),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'location': location?.toJson(),
      'group': group?.toJson(),
      'access_code': accessCode,
      'catalog_config': catalogConfig,
      'rfid_config': rfidConfig.toJson(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Kiosk copyWith({
    int? id,
    String? name,
    String? slug,
    String? description,
    KioskLocation? location,
    KioskGroupRef? group,
    String? accessCode,
    Map<String, dynamic>? catalogConfig,
    KioskRfidConfig? rfidConfig,
    DateTime? createdAt,
  }) {
    return Kiosk(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      location: location ?? this.location,
      group: group ?? this.group,
      accessCode: accessCode ?? this.accessCode,
      catalogConfig: catalogConfig ?? this.catalogConfig,
      rfidConfig: rfidConfig ?? this.rfidConfig,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Kiosk{id: $id, name: $name, slug: $slug, '
      'group: ${group?.id}, location: ${location?.id}}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Kiosk &&
        other.id == id &&
        other.name == name &&
        other.slug == slug &&
        other.description == description &&
        other.location == location &&
        other.group == group &&
        other.accessCode == accessCode &&
        other.rfidConfig == rfidConfig &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        slug,
        description,
        location,
        group,
        accessCode,
        rfidConfig,
        createdAt,
      );
}
