import 'group_settings.dart';

/// The group the kiosk device belongs to — the highest-level entity in the
/// kiosk. Only the root fields and the `group_settings` object are relevant to
/// the kiosk; `count_settings` / `delivery_settings` (used by the field app) are
/// intentionally dropped.
class Group {
  /// Group's unique id.
  final int id;

  /// Parent customer/tenant id.
  final int tenantId;

  final String name;
  final String label;
  final String description;
  final GroupSettings settings;

  const Group({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.label,
    required this.description,
    required this.settings,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as int,
      tenantId: json['tenant_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      label: json['label'] as String? ?? json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      settings: GroupSettings.fromJson(
        json['group_settings'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'label': label,
      'description': description,
      'group_settings': settings.toJson(),
    };
  }

  Group copyWith({
    int? id,
    int? tenantId,
    String? name,
    String? label,
    String? description,
    GroupSettings? settings,
  }) {
    return Group(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      label: label ?? this.label,
      description: description ?? this.description,
      settings: settings ?? this.settings,
    );
  }

  @override
  String toString() =>
      'Group{id: $id, tenantId: $tenantId, name: $name, label: $label}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Group &&
        other.id == id &&
        other.tenantId == tenantId &&
        other.name == name &&
        other.label == label &&
        other.description == description &&
        other.settings == settings;
  }

  @override
  int get hashCode =>
      Object.hash(id, tenantId, name, label, description, settings);
}
