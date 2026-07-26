/// Configuration for tag processing behavior (batching / throttling /
/// backpressure). Mirrors the field app's defaults so the kiosk buffers and
/// paces reads the same way.
class TagProcessingConfig {
  final Duration batchInterval;
  final int maxBatchSize;
  final Duration throttleInterval;
  final int maxQueueSize;

  const TagProcessingConfig({
    this.batchInterval = const Duration(milliseconds: 50),
    this.maxBatchSize = 20,
    this.throttleInterval = const Duration(milliseconds: 50),
    this.maxQueueSize = 1000,
  });
}
