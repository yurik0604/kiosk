import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';

/// OS-level network status, mirrored into Riverpod state.
///
/// Reflects whether the device reports an active network interface (Wi-Fi,
/// ethernet, mobile, etc.) as read from the platform via `connectivity_plus`
/// (Android `ConnectivityManager` and the equivalent on other platforms). This
/// is "is a network connected?", not a guarantee that the network can reach the
/// internet — a deliberate choice for a fixed-install kiosk on managed Wi-Fi.
enum ConnectivityStatus {
  /// Status has not been read yet (initial state).
  unknown,

  /// The device has at least one active, non-`none` network interface.
  online,

  /// The device reports no active network interface.
  offline,
}

extension ConnectivityStatusX on ConnectivityStatus {
  bool get isOnline => this == ConnectivityStatus.online;
}

class ConnectivityState {
  const ConnectivityState({required this.status});

  factory ConnectivityState.initial() =>
      const ConnectivityState(status: ConnectivityStatus.unknown);

  final ConnectivityStatus status;

  ConnectivityState copyWith({ConnectivityStatus? status}) =>
      ConnectivityState(status: status ?? this.status);
}

final connectivityControllerProvider =
    NotifierProvider<ConnectivityController, ConnectivityState>(
  ConnectivityController.new,
);

/// Single source of truth for OS network status.
///
/// Subscribes to the platform connectivity stream and mirrors it into
/// [ConnectivityState.status]. No HTTP polling — the OS pushes changes as the
/// network interface goes up/down, so the indicator updates immediately.
class ConnectivityController extends Notifier<ConnectivityState> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  ConnectivityState build() {
    ref.onDispose(() {
      _sub?.cancel();
    });
    return ConnectivityState.initial();
  }

  /// Read the current network state, then listen for changes. Call from boot.
  Future<void> start() async {
    if (_sub != null) return;
    _sub = _connectivity.onConnectivityChanged.listen(
      _apply,
      onError: (Object e) {
        AppLogger.instance.w('Connectivity stream error: $e');
        _setStatus(ConnectivityStatus.offline);
      },
    );
    try {
      _apply(await _connectivity.checkConnectivity());
    } catch (e) {
      AppLogger.instance.w('Initial connectivity check failed: $e');
      _setStatus(ConnectivityStatus.offline);
    }
  }

  void _apply(List<ConnectivityResult> results) {
    final connected =
        results.any((r) => r != ConnectivityResult.none) && results.isNotEmpty;
    _setStatus(
      connected ? ConnectivityStatus.online : ConnectivityStatus.offline,
    );
  }

  void _setStatus(ConnectivityStatus status) {
    if (state.status == status) return;
    state = state.copyWith(status: status);
  }
}
