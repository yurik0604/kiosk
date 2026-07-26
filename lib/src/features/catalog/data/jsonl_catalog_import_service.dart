import 'dart:convert';
import 'dart:io';

import '../../../../objectbox.g.dart';
import '../../../core/logging/app_logger.dart';
import 'catalog_item_mapper.dart';

final _log = AppLogger.instance;

/// Streaming JSONL.GZ → ObjectBox import.
///
/// Memory-efficient pipeline:
/// ```
/// file bytes → gzip.decoder → utf8.decoder → LineSplitter
///   → jsonDecode → batch (5000) → putMany (background isolate)
/// ```
/// The full uncompressed data is never held in memory.
class JsonlCatalogImportService {
  /// Batch size for `putMany` transactions — balances isolate round-trips
  /// against memory usage.
  static const int _batchSize = 5000;

  /// Import a `.jsonl.gz` file into ObjectBox. Returns the item count.
  Future<int> importJsonlGz({
    required String filePath,
    required Store store,
    int? itemCount,
    void Function(int processed, int total)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('JSONL file not found: $filePath');
    }

    final stream = file
        .openRead()
        .transform(gzip.decoder)
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    var totalProcessed = 0;
    var batch = <Map<String, dynamic>>[];
    final estimatedTotal = itemCount ?? 0;

    await for (final line in stream) {
      if (line.isEmpty) continue;

      batch.add(jsonDecode(line) as Map<String, dynamic>);

      if (batch.length >= _batchSize) {
        await store.runInTransactionAsync(
          TxMode.write,
          batchInsertCallback,
          batch,
        );
        totalProcessed += batch.length;
        batch = <Map<String, dynamic>>[];
        onProgress?.call(totalProcessed, estimatedTotal);
      }
    }

    if (batch.isNotEmpty) {
      await store.runInTransactionAsync(
        TxMode.write,
        batchInsertCallback,
        batch,
      );
      totalProcessed += batch.length;
    }

    onProgress?.call(totalProcessed, totalProcessed);

    stopwatch.stop();
    _log.i('JsonlCatalogImportService: imported $totalProcessed items '
        'in ${stopwatch.elapsed.inMilliseconds}ms');

    return totalProcessed;
  }
}
