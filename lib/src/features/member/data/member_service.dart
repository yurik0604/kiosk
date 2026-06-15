import 'dart:async';

import '../../../core/logging/app_logger.dart';
import '../domain/member.dart';

final _log = AppLogger.instance;

class MemberNotFoundException implements Exception {
  MemberNotFoundException(this.query);
  final String query;
  @override
  String toString() => 'Member not found for "$query"';
}

class MemberLookupException implements Exception {
  MemberLookupException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Looks up a club member by phone or member ID.
///
/// Currently mocked: the only recognized member is phone `0543383969`
/// (mapped to "Yuri"). Any other input resolves to [MemberNotFoundException].
/// Replace [lookup] with a real HTTP call when the backend endpoint is ready.
class MemberService {
  MemberService();

  static const Duration _mockDelay = Duration(milliseconds: 800);

  static String _normalize(String raw) =>
      raw.replaceAll(RegExp(r'[\s\-()]'), '');

  Future<Member> lookup(String query) async {
    final normalized = _normalize(query);
    _log.i('MemberService.lookup query="$normalized"');

    await Future<void>.delayed(_mockDelay);

    if (normalized == '0543383969') {
      // Labels/descriptions are intentionally empty: the UI looks up
      // translated copy from l10n via the benefit `code` and the member `tier`.
      return const Member(
        id: 'M-0001',
        fullName: 'Yuri',
        phone: '0543383969',
        email: 'yuri@example.com',
        tier: 'gold',
        points: 1280,
        discountPct: 5,
        benefits: [
          MemberBenefit(code: 'member_discount', label: ''),
          MemberBenefit(code: 'birthday_gift', label: ''),
          MemberBenefit(code: 'early_access', label: ''),
        ],
      );
    }

    throw MemberNotFoundException(normalized);
  }
}
