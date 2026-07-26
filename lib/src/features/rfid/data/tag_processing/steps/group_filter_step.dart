import '../../../../../core/logging/app_logger.dart';
import '../../../../group/domain/group_settings.dart';
import '../../../domain/tag.dart';
import 'base_step.dart';

/// Filters tags based on the group's barcode standards and customer prefixes.
/// Runs after [BarcodeDecodeStep] to filter decoded tags based on group
/// settings.
class GroupFilterStep extends TagProcessingStep {
  final GroupSettings? groupSettings;

  GroupFilterStep({
    this.groupSettings,
    super.useMetrics = false,
  });

  static final _log = AppLogger.instance;

  @override
  String get name => 'GroupFilterStep';

  @override
  int get priority => 15; // After BarcodeDecodeStep (1).

  /// Filter tags based on group settings.
  @override
  Future<List<Tag>> process(dynamic input) async {
    final tags = input as List<Tag>;
    // If no group settings configured, pass all tags through.
    if (groupSettings == null) {
      _log.w('GroupFilterStep: No group settings configured, passing all tags');
      return tags;
    }

    // If both lists are empty, no filtering needed.
    if (groupSettings!.barcodeStandards.isEmpty &&
        groupSettings!.customerPrefixes.isEmpty) {
      _log.w('GroupFilterStep: No filtering criteria set, passing all tags');
      return tags;
    }

    final filteredTags = <Tag>[];

    // Only track metrics if enabled.
    int totalProcessed = 0;
    int barcodeFilteredCount = 0;
    int prefixFilteredCount = 0;
    int passedCount = 0;

    // Process each tag.
    //
    // No result cache here: the filter recomputes its decision from the tag's
    // decoded (format, companyPrefix) each time. barcodeStandards is an O(1)
    // set-style check and customerPrefixes is tiny (typically 1, rarely 2-3),
    // so recomputing is cheaper than building a string cache key + map lookup.
    // A cache keyed on tag.uid was also incorrect: if a weak read transiently
    // mis-decoded a tag, its `false` decision was cached and the tag stayed
    // filtered out for the rest of the session even once it read cleanly.
    for (final tag in tags) {
      if (useMetrics) totalProcessed++;

      bool passedBarcodeFilter = true;
      bool passedPrefixFilter = true;

      // Check barcode standard filter.
      if (groupSettings!.barcodeStandards.isNotEmpty) {
        final barcodeFormat = tag.tagData['format'] as String?;
        if (barcodeFormat != null) {
          // Convert to uppercase before checking.
          final normalizedFormat = barcodeFormat.toUpperCase();
          passedBarcodeFilter =
              groupSettings!.barcodeStandards.contains(normalizedFormat);
          if (!passedBarcodeFilter && useMetrics) {
            barcodeFilteredCount++;
          }
        }
      }

      // Check customer prefix filter with flexible matching.
      if (passedBarcodeFilter && groupSettings!.customerPrefixes.isNotEmpty) {
        final companyPrefix = tag.tagData['companyPrefix'] as String?;
        if (companyPrefix != null) {
          // Flexible matching: check if any stored prefix matches with the
          // decoded prefix. Handles cases where EPCs might have different
          // partition values.
          passedPrefixFilter = groupSettings!.customerPrefixes.any(
              (storedPrefix) =>
                  storedPrefix.startsWith(companyPrefix) ||
                  companyPrefix.startsWith(storedPrefix));
          if (!passedPrefixFilter && useMetrics) {
            prefixFilteredCount++;
          }
        }
      }

      final shouldPass = passedBarcodeFilter && passedPrefixFilter;

      // Add tag if it passed filters.
      if (shouldPass) {
        filteredTags.add(tag);
        if (useMetrics) passedCount++;
      }
    }

    if (useMetrics) {
      final totalFiltered = totalProcessed - passedCount;

      _log.i('GroupFilterStep: Processed $totalProcessed tags, passed $passedCount, filtered $totalFiltered');
      if (totalFiltered > 0) {
        _log.i('GroupFilterStep: Filter reasons - barcode standard: $barcodeFilteredCount, company prefix: $prefixFilteredCount');
        _log.i('GroupFilterStep: Note - A single tag can fail multiple filters');
      }

      // Validation check.
      if (totalProcessed != (passedCount + totalFiltered)) {
        _log.w('GroupFilterStep: Count mismatch! Processed: $totalProcessed, Passed: $passedCount, Filtered: $totalFiltered');
      }
    }

    return filteredTags;
  }
}
