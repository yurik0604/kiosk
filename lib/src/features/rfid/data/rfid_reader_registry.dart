import '../domain/reader_vendor.dart';
import 'channel_rfid_reader.dart';
import 'rfid_reader.dart';

/// Factory that builds the right [RfidReader] for a given vendor.
///
/// Today every vendor is multiplexed through one native plugin
/// (`ChannelRfidReader`) — the native side picks the driver based on the
/// vendor id in the connect payload. If a future vendor needs a wholly
/// separate Flutter plugin package, branch on [vendor] here.
class RfidReaderRegistry {
  const RfidReaderRegistry();

  RfidReader create(ReaderVendor vendor) {
    switch (vendor) {
      case ReaderVendor.sensormaticIdx4000:
        return ChannelRfidReader();
    }
  }
}
