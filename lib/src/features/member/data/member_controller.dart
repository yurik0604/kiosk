import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/member.dart';
import '../domain/member_state.dart';
import 'member_service.dart';

final memberServiceProvider = Provider<MemberService>((ref) => MemberService());

class MemberController extends Notifier<MemberStateData> {
  @override
  MemberStateData build() => const MemberStateData.idle();

  MemberService get _service => ref.read(memberServiceProvider);

  /// Looks up a member by phone or membership ID. The query is kept on state
  /// so the modal can offer "retry" with the same value after a failure.
  Future<bool> lookup(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return false;

    state = MemberStateData(
      status: MemberStatus.looking,
      lastQuery: trimmed,
    );
    try {
      final member = await _service.lookup(trimmed);
      state = MemberStateData(
        status: MemberStatus.attached,
        member: member,
        lastQuery: trimmed,
      );
      return true;
    } on MemberNotFoundException {
      state = MemberStateData(
        status: MemberStatus.notFound,
        lastQuery: trimmed,
      );
      return false;
    } on MemberLookupException catch (e) {
      state = MemberStateData(
        status: MemberStatus.error,
        lastQuery: trimmed,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = MemberStateData(
        status: MemberStatus.error,
        lastQuery: trimmed,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void attachManually(Member member) {
    state = MemberStateData(
      status: MemberStatus.attached,
      member: member,
      lastQuery: member.phone.isNotEmpty ? member.phone : member.id,
    );
  }

  /// Clears any in-flight lookup or attached member. Call when the kiosk
  /// session ends (cancel, completed checkout, returning to home).
  void clear() {
    state = const MemberStateData.idle();
  }
}

final memberControllerProvider =
    NotifierProvider<MemberController, MemberStateData>(MemberController.new);
