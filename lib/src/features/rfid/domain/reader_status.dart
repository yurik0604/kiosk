/// Lifecycle states aligned with LLRP reader events and common vendor SDKs.
///
/// Transitions follow this rough order:
///   offline → connecting → connected → reading ↔ idle → disconnected → offline
/// `error` can occur from any state.
enum ReaderStatus {
  /// No transport open. Initial state and the state after fatal errors.
  offline,

  /// Transport handshake in progress (TCP connect, SDK pairing, etc.).
  connecting,

  /// Transport up and reader is responsive but not actively reading.
  connected,

  /// Inventory is running (LLRP ROSpec enabled / SDK reading).
  reading,

  /// Reader is connected but inventory has been stopped on purpose.
  idle,

  /// Graceful shutdown of the transport.
  disconnected,

  /// Last operation produced an error; see accompanying [ReaderError] message.
  error,
}

extension ReaderStatusX on ReaderStatus {
  bool get isConnected =>
      this == ReaderStatus.connected ||
      this == ReaderStatus.reading ||
      this == ReaderStatus.idle;

  bool get canStart =>
      this == ReaderStatus.connected || this == ReaderStatus.idle;

  bool get canStop => this == ReaderStatus.reading;
}
