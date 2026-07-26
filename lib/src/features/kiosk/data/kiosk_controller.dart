import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/logging/app_logger.dart';
import '../../auth/data/auth_controller.dart';
import '../../auth/data/secure_storage.dart';
import '../../rfid/data/rfid_reader_controller.dart';
import '../domain/kiosk.dart';
import '../domain/kiosk_state.dart';
import 'kiosk_service.dart';

final _log = AppLogger.instance;

/// Owns the device's kiosk state (the `Kiosks` swagger entity) — globally
/// available via [kioskControllerProvider].
///
/// The kiosk is fetched from `GET v1/kiosks/me/` right after a successful
/// login/session-restore (the backend resolves it from the bearer token). This
/// model is essential to kiosk functionality: if it can't be resolved (404 /
/// 500 / no kiosk), [initialize] returns `false` and the loading flow blocks the
/// home screen (see the kiosk-not-defined screen).
///
/// The resolved kiosk is persisted to secure storage so it's available offline
/// and instantly on the next boot.
class KioskController extends Notifier<KioskStateData> {
  final SecureStorage _storage = SecureStorage();

  @override
  KioskStateData build() => const KioskStateData.unknown();

  KioskService get _service => ref.read(kioskServiceProvider);

  /// Fetch and initialize the device's kiosk after authentication.
  ///
  /// Returns `true` when a kiosk is ready (freshly fetched OR restored from
  /// cache when the network is momentarily unavailable), `false` when the kiosk
  /// is not defined / can't be loaded and there is no usable cache — in which
  /// case the caller must NOT open the home screen.
  Future<bool> initialize() async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isAuthenticated) {
      _log.w('KioskController: not authenticated; cannot resolve kiosk');
      state = const KioskStateData.error('Not authenticated');
      return false;
    }

    final slug = auth.user?.tenantSlug;

    // Restore the cache first so a momentary network blip doesn't lock a device
    // that was already provisioned. A fresh fetch still runs and wins.
    final cached = await _readCachedKiosk();
    if (cached != null && cached.id != 0) {
      state = KioskStateData.ready(cached);
      // Configure the reader from the cached server config immediately so an
      // offline boot still has a working reader; a fresh fetch re-inits below.
      _initReaderFromKiosk(cached);
    } else {
      state = const KioskStateData.loading();
    }

    try {
      final kiosk = await _service.fetchMyKiosk(tenantSlug: slug);
      state = KioskStateData.ready(kiosk);
      await _persist(kiosk);
      // Server is the source of truth: (re)initialize the reader from the fresh
      // rfid_config, overriding any cached/local runtime state.
      _initReaderFromKiosk(kiosk);
      _log.i('KioskController: kiosk ${kiosk.id} initialized');
      return true;
    } on KioskUnavailableException catch (e) {
      // A definitive "not defined" (404) invalidates any stale cache — the
      // kiosk was removed/reassigned. Block regardless of cache.
      if (e.notDefined) {
        await _storage.delete(AppConfig.kioskStorageKey);
        state = KioskStateData.error(e.message, reason: e.reason);
        _log.w('KioskController: kiosk not defined for the current user');
        return false;
      }
      // Server error / network: fall back to cache if we have one.
      if (state.isReady) {
        _log.w('KioskController: fetch failed (${e.message}); '
            'using cached kiosk ${state.kioskId}');
        return true;
      }
      state = KioskStateData.error(e.message, reason: e.reason);
      _log.w('KioskController: kiosk unavailable and no cache: ${e.message}');
      return false;
    } catch (e, st) {
      _log.e('KioskController: unexpected fetch error', error: e, stackTrace: st);
      if (state.isReady) return true;
      state = KioskStateData.error(
        e.toString(),
        reason: KioskFailureReason.serverError,
      );
      return false;
    }
  }

  /// Peek the cached kiosk from storage WITHOUT committing it to state. Returns
  /// null when there's no cache or it can't be parsed (clearing bad data).
  Future<Kiosk?> _readCachedKiosk() async {
    try {
      final raw = await _storage.read(AppConfig.kioskStorageKey);
      if (raw == null || raw.isEmpty) return null;
      return Kiosk.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      _log.w('KioskController: failed to read cached kiosk: $e');
      await _storage.delete(AppConfig.kioskStorageKey);
      return null;
    }
  }

  Future<void> _persist(Kiosk kiosk) async {
    try {
      await _storage.write(
        AppConfig.kioskStorageKey,
        jsonEncode(kiosk.toJson()),
      );
    } catch (e) {
      _log.w('KioskController: failed to persist kiosk: $e');
    }
  }

  /// (Re)configure the RFID reader from the kiosk's server `rfid_config`.
  ///
  /// Fire-and-forget: reader connect must never block the kiosk gate. The reader
  /// controller treats the server config as the source of truth (see
  /// `RfidReaderController.initFromServer`), so this overrides any prior runtime
  /// state on every boot.
  void _initReaderFromKiosk(Kiosk kiosk) {
    final readerConfig = kiosk.rfidConfig.toReaderConfig();
    unawaited(
      ref
          .read(rfidReaderControllerProvider.notifier)
          .initFromServer(readerConfig)
          .catchError((Object e, StackTrace st) {
        _log.w('KioskController: reader init from rfid_config failed: $e');
      }),
    );
  }

  /// Clear kiosk state and storage (on logout).
  Future<void> clear() async {
    await _storage.delete(AppConfig.kioskStorageKey);
    state = const KioskStateData.unknown();
  }
}

final kioskControllerProvider =
    NotifierProvider<KioskController, KioskStateData>(KioskController.new);
