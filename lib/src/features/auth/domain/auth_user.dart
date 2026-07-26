class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    this.fullName = '',
    this.tenantId,
    this.tenantSlug,
    this.role,
    this.customerGroupIds = const [],
  });

  final int id;
  final String username;
  final String email;
  final String fullName;
  final int? tenantId;
  final String? tenantSlug;
  final String? role;

  /// Group ids this user has access to. The kiosk uses the first one as the
  /// device's group.
  final List<int> customerGroupIds;

  String get displayName => fullName.isNotEmpty ? fullName : username;

  AuthUser copyWith({
    int? id,
    String? username,
    String? email,
    String? fullName,
    int? tenantId,
    String? tenantSlug,
    String? role,
    List<int>? customerGroupIds,
  }) {
    return AuthUser(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      tenantId: tenantId ?? this.tenantId,
      tenantSlug: tenantSlug ?? this.tenantSlug,
      role: role ?? this.role,
      customerGroupIds: customerGroupIds ?? this.customerGroupIds,
    );
  }

  /// Merge [other] onto this user, keeping this user's tenant identity
  /// (`tenantId` / `tenantSlug` / `customerGroupIds`) whenever [other] leaves
  /// those blank.
  ///
  /// The login token response carries `tenant_slug` / `tenant_id`, but the
  /// `/v1/users/me/` payload can return them null/empty for some deployments.
  /// Merging (rather than replacing) prevents a later `/me/` hydrate from wiping
  /// the tenant slug the login provided — losing it breaks tenant-routed calls
  /// (e.g. the kiosk fetch) after a restart.
  AuthUser mergePreservingTenant(AuthUser other) {
    return other.copyWith(
      tenantId: other.tenantId ?? tenantId,
      tenantSlug: (other.tenantSlug != null && other.tenantSlug!.isNotEmpty)
          ? other.tenantSlug
          : tenantSlug,
      customerGroupIds: other.customerGroupIds.isNotEmpty
          ? other.customerGroupIds
          : customerGroupIds,
    );
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      tenantId: json['tenant_id'] as int?,
      tenantSlug: json['tenant_slug'] as String?,
      role: json['role']?.toString(),
      customerGroupIds: (json['customer_group_ids'] as List<dynamic>?)
              ?.map((e) => e is int ? e : int.parse(e.toString()))
              .toList() ??
          const [],
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
        'customer_group_ids': customerGroupIds,
      };
}
