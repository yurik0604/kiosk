import '../../../../core/logging/app_logger.dart';
import '../../../group/domain/group_settings.dart';
import '../../domain/rfid_tag.dart';
import '../../domain/tag.dart';
import 'steps/barcode_decode_step.dart';
import 'steps/base_step.dart';
import 'steps/group_filter_step.dart';

/// Main orchestrator for the tag processing pipeline.
///
/// Runs the ordered chain of [TagProcessingStep]s over a batch of raw reads:
/// the first step ([BarcodeDecodeStep], priority 1) turns `List<RfidTag>` into
/// `List<Tag>`, and each subsequent step transforms the `List<Tag>` further.
class TagProcessingPipeline {
  static final _log = AppLogger.instance;

  final List<TagProcessingStep> _steps = [];
  final bool useMetrics;

  // Pipeline statistics.
  int _totalBatchesProcessed = 0;
  int _totalTagsProcessed = 0;
  int _totalErrors = 0;

  // Optional, runtime-managed group filter step.
  GroupFilterStep? _groupFilterStep;

  TagProcessingPipeline({
    this.useMetrics = false,
    bool useDefaultSteps = true,
  }) {
    if (useDefaultSteps) {
      _initializeDefaultSteps();
    }
  }

  /// Initialize default processing steps.
  void _initializeDefaultSteps() {
    // Barcode decode step (priority 1 - highest).
    addStep(BarcodeDecodeStep(useMetrics: useMetrics));
  }

  /// Add a processing step to the pipeline.
  void addStep(TagProcessingStep step) {
    _steps.add(step);
    _sortSteps();
    _log.d('Pipeline: Added step [${step.name}] (priority: ${step.priority})');
  }

  /// Remove a processing step from the pipeline.
  void removeStep(String stepName) {
    _steps.removeWhere((step) => step.name == stepName);
    _log.d('Pipeline: Removed step [$stepName]');
  }

  /// Sort steps by priority.
  void _sortSteps() {
    _steps.sort((a, b) => a.priority.compareTo(b.priority));
  }

  /// Process a batch of RFID tags through the pipeline.
  /// Executes all steps in order based on priority.
  Future<ProcessingResult> processBatch(List<RfidTag> rfidTags) async {
    if (rfidTags.isEmpty) {
      return ProcessingResult.empty();
    }

    if (_steps.isEmpty) {
      _log.w('Pipeline: No steps configured');
      return ProcessingResult.empty();
    }

    _log.d('Pipeline: Starting batch processing of ${rfidTags.length} RFID tags through ${_steps.length} steps');

    try {
      // Execute steps in order by priority.
      // input can be List<RfidTag> or List<Tag> depending on the step.
      List<dynamic> tags = rfidTags;

      for (int i = 0; i < _steps.length; i++) {
        final step = _steps[i];
        // Process and update input for the next step.
        tags = await step.process(tags);
        _log.d('Pipeline: Step ${i + 1}/${_steps.length} [${step.name}] - ${tags.length} tags');
      }

      // Update statistics only if metrics are enabled.
      if (useMetrics) {
        _totalBatchesProcessed++;
        _totalTagsProcessed += tags.length;
      }

      _log.d('Pipeline: Batch processing completed - ${tags.length}/${rfidTags.length} tags');

      return ProcessingResult(tags: tags.cast<Tag>());
    } catch (error) {
      // Update error statistics only if metrics are enabled.
      if (useMetrics) {
        _totalErrors++;
      }
      _log.e('Pipeline: Fatal error during processing: $error');
      // Return empty result on error.
      return ProcessingResult(tags: const []);
    }
  }

  /// Get pipeline configuration.
  Map<String, dynamic> getConfiguration() {
    return {
      'useMetrics': useMetrics,
      'steps': _steps
          .map((step) => {
                'name': step.name,
                'priority': step.priority,
              })
          .toList(),
    };
  }

  /// Get pipeline statistics.
  Map<String, dynamic> getStatistics() {
    if (!useMetrics) {
      return {
        'error':
            'Metrics collection is disabled. Set useMetrics=true to enable statistics.',
      };
    }

    final stepStats = <String, dynamic>{};

    for (final step in _steps) {
      stepStats[step.name] = step.getStatistics();
    }

    return {
      'totalBatchesProcessed': _totalBatchesProcessed,
      'totalTagsProcessed': _totalTagsProcessed,
      'totalErrors': _totalErrors,
      'errorRate':
          _totalTagsProcessed > 0 ? _totalErrors / _totalTagsProcessed : 0.0,
      'steps': stepStats,
    };
  }

  /// Reset all statistics.
  void resetStatistics() {
    if (!useMetrics) {
      _log.w('Pipeline: Cannot reset statistics - metrics collection is disabled');
      return;
    }

    _totalBatchesProcessed = 0;
    _totalTagsProcessed = 0;
    _totalErrors = 0;

    for (final step in _steps) {
      step.resetMetrics();
    }

    _log.i('Pipeline: Statistics reset');
  }

  /// Clear all caches from cacheable steps.
  void clearAllCaches() {
    int clearedCaches = 0;

    for (final step in _steps) {
      if (step is CacheableStep) {
        step.clearCache();
        clearedCaches++;
        _log.d('Pipeline: Cache cleared for step [${step.name}]');
      }
    }

    _log.i('Pipeline: All caches cleared ($clearedCaches steps)');
  }

  /// Update or set group settings for filtering.
  void updateGroupSettings(GroupSettings? groupSettings) {
    // Remove existing group filter step if it exists.
    if (_groupFilterStep != null) {
      removeStep(_groupFilterStep!.name);
      _groupFilterStep = null;
    }

    // Add new group filter step if settings are provided.
    if (groupSettings != null) {
      _groupFilterStep = GroupFilterStep(
        groupSettings: groupSettings,
        useMetrics: useMetrics,
      );
      addStep(_groupFilterStep!);
      _log.i('Pipeline: Group filter configured with ${groupSettings.barcodeStandards.length} barcode standards and ${groupSettings.customerPrefixes.length} prefixes');
    } else {
      _log.d('Pipeline: Group filter removed - no group settings');
    }
  }
}

/// Result of pipeline processing.
class ProcessingResult {
  final List<Tag> tags;

  ProcessingResult({required this.tags});

  factory ProcessingResult.empty() {
    return ProcessingResult(tags: const []);
  }

  bool get hasErrors => false; // Kept for backwards compatibility.

  Map<String, dynamic> toMap() {
    return {
      'tagCount': tags.length,
    };
  }
}
