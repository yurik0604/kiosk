class MemberBenefit {
  const MemberBenefit({
    required this.code,
    required this.label,
    this.description,
  });

  final String code;
  final String label;
  final String? description;

  factory MemberBenefit.fromJson(Map<String, dynamic> json) {
    return MemberBenefit(
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'label': label,
        if (description != null) 'description': description,
      };
}

class Member {
  const Member({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.tier,
    this.points = 0,
    this.discountPct = 0,
    this.benefits = const [],
  });

  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String? tier;
  final int points;

  /// Flat percentage discount applied to every line during a session.
  /// 0 means no member discount; a value of 5 means 5% off.
  final double discountPct;
  final List<MemberBenefit> benefits;

  String get firstName {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return '';
    final space = trimmed.indexOf(' ');
    return space == -1 ? trimmed : trimmed.substring(0, space);
  }

  factory Member.fromJson(Map<String, dynamic> json) {
    final rawBenefits = json['benefits'];
    return Member(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ??
          json['name']?.toString() ??
          '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      tier: json['tier']?.toString(),
      points: (json['points'] as num?)?.toInt() ?? 0,
      discountPct: (json['discount_pct'] as num?)?.toDouble() ?? 0,
      benefits: rawBenefits is List
          ? rawBenefits
              .whereType<Map<String, dynamic>>()
              .map(MemberBenefit.fromJson)
              .toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'phone': phone,
        if (email != null) 'email': email,
        if (tier != null) 'tier': tier,
        'points': points,
        'discount_pct': discountPct,
        'benefits': benefits.map((b) => b.toJson()).toList(),
      };
}
