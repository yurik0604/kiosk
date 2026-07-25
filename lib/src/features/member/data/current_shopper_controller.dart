import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/member.dart';

/// The current shopper for the active session: an optional attached [member]
/// plus an optionally-captured [phone].
///
/// This is the single, session-scoped source of truth for "who is checking out"
/// — accessible anywhere in the app (member lookup, checkout, receipt delivery).
/// A guest with no membership can still have a [phone] (e.g. captured to SMS a
/// receipt); a member always contributes their own phone as a fallback.
class CurrentShopperState {
  const CurrentShopperState({this.member, this.phone});

  /// The attached loyalty member, if the shopper identified themselves.
  final Member? member;

  /// A phone number captured for this session (e.g. for an SMS receipt), taking
  /// precedence over the member's on-file phone when set.
  final String? phone;

  /// The best phone number available: an explicitly-captured [phone], else the
  /// attached member's on-file phone. `null` when neither is known.
  String? get effectivePhone {
    final p = phone?.trim();
    if (p != null && p.isNotEmpty) return p;
    final memberPhone = member?.phone.trim();
    if (memberPhone != null && memberPhone.isNotEmpty) return memberPhone;
    return null;
  }

  /// Whether any phone number is on hand for delivery.
  bool get hasPhone => effectivePhone != null;

  CurrentShopperState copyWith({
    Member? member,
    String? phone,
    bool clearMember = false,
    bool clearPhone = false,
  }) {
    return CurrentShopperState(
      member: clearMember ? null : (member ?? this.member),
      phone: clearPhone ? null : (phone ?? this.phone),
    );
  }
}

class CurrentShopperController extends Notifier<CurrentShopperState> {
  @override
  CurrentShopperState build() => const CurrentShopperState();

  /// Attaches (or replaces) the identified member for this session.
  void setMember(Member member) {
    state = state.copyWith(member: member);
  }

  /// Records a phone number captured during the session (e.g. for SMS receipts).
  void setPhone(String phone) {
    state = state.copyWith(phone: phone.trim());
  }

  /// Clears everything — call when a session ends and a new shopper begins.
  void clear() {
    state = const CurrentShopperState();
  }
}

final currentShopperProvider =
    NotifierProvider<CurrentShopperController, CurrentShopperState>(
      CurrentShopperController.new,
    );
