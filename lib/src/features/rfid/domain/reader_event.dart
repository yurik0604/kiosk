import 'reader_status.dart';
import 'rfid_tag.dart';

/// Single event stream from any reader driver. Matches the EventChannel
/// payloads emitted by the Android side.
sealed class ReaderEvent {
  const ReaderEvent();

  factory ReaderEvent.fromMap(Map<dynamic, dynamic> map) {
    final type = map['type'] as String;
    switch (type) {
      case 'status':
        return ReaderStatusEvent(
          status: ReaderStatus.values.byName(map['status'] as String),
          message: map['message'] as String?,
        );
      case 'tags':
        final raw = (map['tags'] as List).cast<Map>();
        return ReaderTagsEvent(
          tags: raw.map(RfidTag.fromMap).toList(growable: false),
        );
      case 'error':
        return ReaderErrorEvent(
          message: map['message'] as String? ?? 'unknown error',
          code: map['code'] as String?,
          fatal: map['fatal'] as bool? ?? false,
        );
      default:
        throw ArgumentError('Unknown ReaderEvent type: $type');
    }
  }
}

class ReaderStatusEvent extends ReaderEvent {
  const ReaderStatusEvent({required this.status, this.message});
  final ReaderStatus status;
  final String? message;
}

class ReaderTagsEvent extends ReaderEvent {
  const ReaderTagsEvent({required this.tags});
  final List<RfidTag> tags;
}

class ReaderErrorEvent extends ReaderEvent {
  const ReaderErrorEvent({
    required this.message,
    this.code,
    this.fatal = false,
  });
  final String message;
  final String? code;

  /// If true, the driver has transitioned to [ReaderStatus.offline] and
  /// the caller must call `connect()` again to recover.
  final bool fatal;
}
