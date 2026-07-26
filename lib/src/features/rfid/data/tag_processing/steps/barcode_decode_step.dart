import '../../../../../core/logging/app_logger.dart';
import '../../../domain/rfid_tag.dart';
import '../../../domain/tag.dart';
import 'base_step.dart';

/// First mandatory step that decodes EPC to barcode and converts [RfidTag] to
/// [Tag]. This step MUST run first in the pipeline to establish the foundation
/// for all other processing.
class BarcodeDecodeStep extends TagProcessingStep with CacheableStep {
  BarcodeDecodeStep({
    super.useMetrics = false,
  });

  static final _log = AppLogger.instance;

  @override
  String get name => 'BarcodeDecodeStep';

  @override
  int get priority => 1; // Highest priority - MUST run first.

  /// Process RFID tags and convert them to [Tag] objects.
  @override
  Future<List<Tag>> process(dynamic input) async {
    final rfidTags = input as List<RfidTag>;
    final decodedTags = <Tag>[];

    // Only track metrics if enabled.
    int successfulDecodes = 0;
    int failedDecodes = 0;
    int cacheHits = 0;

    for (final rfidTag in rfidTags) {
      try {
        // Check cache first (keyed on EPC only) to reuse a decoded tag.
        final cacheKey = rfidTag.epc;
        var tag = getCached<Tag>(cacheKey);

        if (tag == null) {
          // Tag not in cache, need to decode it.
          try {
            // fromRfidTag automatically uses the current encoding standard.
            tag = Tag.fromRfidTag(rfidTag);
            if (useMetrics) successfulDecodes++;

            // Cache the decoded tag.
            setCached(cacheKey, tag);

            // Add to results.
            decodedTags.add(tag);
          } catch (error) {
            _log.d('BarcodeDecodeStep failed decode epc (${rfidTag.epc}): $error');
            if (useMetrics) failedDecodes++;
            continue;
          }
        } else {
          // Tag found in cache - reuse it with the current read's timestamp.
          if (useMetrics) cacheHits++;

          final updatedTag = tag.copyWith(readTime: rfidTag.readTime);
          decodedTags.add(updatedTag);
        }
      } catch (error) {
        if (useMetrics) failedDecodes++;
        _log.d('BarcodeDecodeStep: Failed to process tag ${rfidTag.epc}: $error');
      }
    }

    if (useMetrics) {
      final totalProcessed = decodedTags.length;
      _log.d('BarcodeDecodeStep: Processed $totalProcessed/${rfidTags.length} tags');
      _log.d('BarcodeDecodeStep: New decodes: $successfulDecodes, Cache hits: $cacheHits, Failed: $failedDecodes');
    }

    return decodedTags;
  }
}
