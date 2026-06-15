import 'member.dart';

enum MemberStatus { idle, looking, attached, notFound, error }

class MemberStateData {
  const MemberStateData({
    required this.status,
    this.member,
    this.lastQuery,
    this.errorMessage,
  });

  final MemberStatus status;
  final Member? member;
  final String? lastQuery;
  final String? errorMessage;

  const MemberStateData.idle()
      : status = MemberStatus.idle,
        member = null,
        lastQuery = null,
        errorMessage = null;

  bool get isAttached => status == MemberStatus.attached && member != null;
  bool get isLooking => status == MemberStatus.looking;

  MemberStateData copyWith({
    MemberStatus? status,
    Member? member,
    String? lastQuery,
    String? errorMessage,
  }) {
    return MemberStateData(
      status: status ?? this.status,
      member: member ?? this.member,
      lastQuery: lastQuery ?? this.lastQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
