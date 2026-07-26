import 'group.dart';

enum GroupStatus {
  unknown,
  loading,
  ready,
  error,
}

/// State of the kiosk's group: its root fields + `group_settings`.
class GroupStateData {
  const GroupStateData({
    required this.status,
    this.group,
    this.error,
  });

  final GroupStatus status;
  final Group? group;
  final String? error;

  const GroupStateData.unknown() : this(status: GroupStatus.unknown);
  const GroupStateData.loading() : this(status: GroupStatus.loading);
  const GroupStateData.ready(Group group)
      : this(status: GroupStatus.ready, group: group);
  const GroupStateData.error(String error)
      : this(status: GroupStatus.error, error: error);

  int? get groupId => group?.id;
  bool get isReady => status == GroupStatus.ready && group != null;
  bool get isLoading => status == GroupStatus.loading;

  GroupStateData copyWith({
    GroupStatus? status,
    Group? group,
    String? error,
    bool clearError = false,
  }) {
    return GroupStateData(
      status: status ?? this.status,
      group: group ?? this.group,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GroupStateData &&
      other.status == status &&
      other.group == group &&
      other.error == error;

  @override
  int get hashCode => Object.hash(status, group, error);
}
