import '../data/kiosk_service.dart';
import 'kiosk.dart';

enum KioskStatus {
  unknown,
  loading,
  ready,
  error,
}

/// Global state of the device's kiosk (the `Kiosks` swagger entity).
class KioskStateData {
  const KioskStateData({
    required this.status,
    this.kiosk,
    this.error,
    this.failureReason,
  });

  final KioskStatus status;
  final Kiosk? kiosk;
  final String? error;

  /// Why the kiosk failed to load (only set when [status] is error). Drives the
  /// blocked-screen message: 404 → "not available for this user"; server error
  /// → "kiosk unavailable, contact IT"; network → "can't reach the server".
  final KioskFailureReason? failureReason;

  const KioskStateData.unknown() : this(status: KioskStatus.unknown);
  const KioskStateData.loading() : this(status: KioskStatus.loading);
  const KioskStateData.ready(Kiosk kiosk)
      : this(status: KioskStatus.ready, kiosk: kiosk);
  const KioskStateData.error(String error, {KioskFailureReason? reason})
      : this(
          status: KioskStatus.error,
          error: error,
          failureReason: reason,
        );

  int? get kioskId => kiosk?.id;
  bool get isReady => status == KioskStatus.ready && kiosk != null;
  bool get isLoading => status == KioskStatus.loading;

  /// True only for the definitive "no kiosk for this user" case (HTTP 404).
  bool get notDefined => failureReason == KioskFailureReason.notDefined;

  KioskStateData copyWith({
    KioskStatus? status,
    Kiosk? kiosk,
    String? error,
    KioskFailureReason? failureReason,
    bool clearError = false,
  }) {
    return KioskStateData(
      status: status ?? this.status,
      kiosk: kiosk ?? this.kiosk,
      error: clearError ? null : (error ?? this.error),
      failureReason: failureReason ?? this.failureReason,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is KioskStateData &&
      other.status == status &&
      other.kiosk == kiosk &&
      other.error == error &&
      other.failureReason == failureReason;

  @override
  int get hashCode => Object.hash(status, kiosk, error, failureReason);
}
