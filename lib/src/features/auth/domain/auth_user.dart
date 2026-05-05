class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    this.fullName = '',
    this.tenantId,
    this.tenantSlug,
    this.role,
  });

  final int id;
  final String username;
  final String email;
  final String fullName;
  final int? tenantId;
  final String? tenantSlug;
  final String? role;

  String get displayName => fullName.isNotEmpty ? fullName : username;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      tenantId: json['tenant_id'] as int?,
      tenantSlug: json['tenant_slug'] as String?,
      role: json['role']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'full_name': fullName,
        if (tenantId != null) 'tenant_id': tenantId,
        if (tenantSlug != null) 'tenant_slug': tenantSlug,
        if (role != null) 'role': role,
      };
}
