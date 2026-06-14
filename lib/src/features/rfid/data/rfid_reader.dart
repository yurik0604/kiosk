import '../domain/reader_config.dart';
import '../domain/reader_event.dart';
import '../domain/reader_status.dart';

/// Vendor-agnostic RFID reader interface.
///
/// One [RfidReader] instance represents one physical reader. Implementations
/// route to the appropriate native plugin (LLRP socket, vendor SDK, ...).
abstract class RfidReader {
  /// Stable id of the underlying vendor driver. Used for diagnostics.
  String get vendorId;

  /// Last known status. Cheap to read; the authoritative stream is [events].
  ReaderStatus get status;

  /// Unified event stream: status changes, tag reports, errors.
  Stream<ReaderEvent> get events;

  /// Open the transport and prepare the reader. Idempotent: calling it while
  /// already connected is a no-op unless [config] differs.
  Future<void> connect(ReaderConfig config);

  /// Stop reading (if active) and close the transport.
  Future<void> disconnect();

  /// Start the inventory ROSpec / SDK read loop.
  Future<void> startInventory();

  /// Stop the inventory ROSpec / SDK read loop. Stays connected.
  Future<void> stopInventory();

  /// Release all resources. After [dispose] the instance is unusable.
  Future<void> dispose();
}
