import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/reader_config.dart';
import '../domain/reader_vendor.dart';

const _storageKey = 'kiosk_rfid_reader_config';

final readerConfigRepositoryProvider = Provider<ReaderConfigRepository>(
  (_) => ReaderConfigRepository(const FlutterSecureStorage()),
);

/// Persists the last-selected reader configuration so the kiosk can
/// auto-reconnect on boot.
///
/// Storage backend is `flutter_secure_storage` for parity with the rest of the
/// app — the data isn't strictly secret, but keeping all on-device config in
/// one place avoids dragging in another storage layer.
class ReaderConfigRepository {
  ReaderConfigRepository(this._storage);

  final FlutterSecureStorage _storage;

  Future<ReaderConfig?> load() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null || raw.isEmpty) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final vendor = ReaderVendor.fromId(map['vendor'] as String?);
    if (vendor == null) return null;
    return ReaderConfig(
      vendor: vendor,
      host: map['host'] as String? ?? '',
      port: (map['port'] as num?)?.toInt() ?? 5084,
      antennaMask: (map['antennaMask'] as num?)?.toInt() ?? 0xFFFF,
      txPowerDbm: (map['txPowerDbm'] as num?)?.toDouble() ?? 30.0,
      preventDuplicates: map['preventDuplicates'] as bool? ?? true,
    );
  }

  Future<void> save(ReaderConfig config) async {
    await _storage.write(
      key: _storageKey,
      value: jsonEncode(config.toChannelMap()),
    );
  }

  Future<void> clear() => _storage.delete(key: _storageKey);
}
