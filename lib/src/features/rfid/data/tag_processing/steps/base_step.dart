import '../../../domain/tag.dart';

/// Base abstract class for all tag processing steps.
/// Steps work directly on tag lists; the first step receives the raw reads and
/// every subsequent step receives the previous step's [Tag] output.
abstract class TagProcessingStep {
  /// Unique name for this step.
  String get name;

  /// Whether metrics collection is enabled.
  final bool useMetrics;

  /// Whether this step can run in parallel with other steps.
  bool get canRunInParallel => false;

  /// Priority for execution order (lower = higher priority).
  int get priority => 100;

  /// Performance metrics (only tracked when useMetrics = true).
  int _processedCount = 0;
  int _errorCount = 0;
  Duration _totalDuration = Duration.zero;

  TagProcessingStep({
    this.useMetrics = false,
  });

  /// Process method that all steps must implement.
  ///
  /// [input] is `dynamic`: the first (priority-1) step receives a
  /// `List<RfidTag>`; all later steps receive a `List<Tag>`. Each step casts
  /// internally.
  Future<List<Tag>> process(dynamic input);

  /// Reset performance metrics.
  void resetMetrics() {
    _processedCount = 0;
    _errorCount = 0;
    _totalDuration = Duration.zero;
  }

  /// Get average processing duration.
  Duration _getAverageDuration() {
    if (_processedCount == 0) return Duration.zero;
    return Duration(
      microseconds: _totalDuration.inMicroseconds ~/ _processedCount,
    );
  }

  /// Get performance statistics.
  Map<String, dynamic> getStatistics() {
    return {
      'name': name,
      'processedCount': _processedCount,
      'errorCount': _errorCount,
      'totalDuration': _totalDuration.inMilliseconds,
      'averageDuration': _getAverageDuration().inMicroseconds,
      'errorRate': _processedCount > 0 ? _errorCount / _processedCount : 0.0,
    };
  }
}

/// Mixin for steps that can cache results.
mixin CacheableStep on TagProcessingStep {
  final Map<String, dynamic> _cache = {};
  int _cacheHits = 0;
  int _cacheMisses = 0;

  /// Get cached value.
  T? getCached<T>(String key) {
    if (_cache.containsKey(key)) {
      if (useMetrics) _cacheHits++;
      return _cache[key] as T?;
    }
    if (useMetrics) _cacheMisses++;
    return null;
  }

  /// Set cached value.
  void setCached(String key, dynamic value) {
    _cache[key] = value;
  }

  /// Clear cache.
  void clearCache() {
    _cache.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
  }

  /// Get cache statistics.
  Map<String, dynamic> getCacheStatistics() {
    return {
      'cacheSize': _cache.length,
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'hitRate': (_cacheHits + _cacheMisses) > 0
          ? _cacheHits / (_cacheHits + _cacheMisses)
          : 0.0,
    };
  }
}
