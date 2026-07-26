import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk/src/features/group/domain/group_settings.dart';
import 'package:kiosk/src/features/rfid/data/encoding/barcode_converter.dart';
import 'package:kiosk/src/features/rfid/data/encoding/xcode_converter.dart';
import 'package:kiosk/src/features/rfid/data/tag_processing/pipeline.dart';
import 'package:kiosk/src/features/rfid/domain/rfid_tag.dart';
import 'package:kiosk/src/features/rfid/domain/tag.dart';

/// End-to-end tests for the ported tag-processing pipeline: raw [RfidTag] reads
/// flow through BarcodeDecodeStep (EPC → Tag) and GroupFilterStep, mirroring the
/// field app's behavior.
void main() {
  // XCode is the encoding standard we exercise here; set it before decoding.
  setUp(() {
    BarcodeConverterFactory.clearCache();
    BarcodeConverterFactory.setCurrentStandard(EncodingStandard.xcode);
  });

  RfidTag readOf(String epc) => RfidTag(
        epc: epc,
        readTime: DateTime.utc(2026, 1, 1),
        rssi: -55,
        antenna: 1,
      );

  // A known XCode-encodable barcode (customer/prefix 100, serial 100).
  String encodeXcode(String barcode, int serial) => XCodeConverter().encodeToEpc(
        barcode: barcode,
        serialNumber: serial,
        companyPrefixLength: 0,
        customerXcodePrefix: 100,
      );

  test('decodes an XCode EPC into a Tag with decoded tagData', () async {
    final epc = encodeXcode('180005085L', 100);
    final pipeline = TagProcessingPipeline();

    final result = await pipeline.processBatch([readOf(epc)]);

    expect(result.tags, hasLength(1));
    final tag = result.tags.single;
    expect(tag.uid, epc);
    expect(tag.barcode, '180005085L');
    expect(tag.tagType, TagType.rfid);
    expect(tag.tagData['gtin'], '180005085L');
    expect(tag.tagData['serialNumber'], '100');
    expect(tag.tagData['companyPrefix'], '100');
    expect(tag.tagData['encodingStandard'], EncodingStandard.xcode.name);
    // RFID read metadata is carried through.
    expect(tag.tagData['rssi'], -55);
    expect(tag.tagData['antenna'], 1);
  });

  test('dedups repeat reads of the same EPC via the decode cache', () async {
    final epc = encodeXcode('1234567890', 500);
    final pipeline = TagProcessingPipeline();

    // Two reads of the same EPC with different timestamps.
    final result = await pipeline.processBatch([
      RfidTag(epc: epc, readTime: DateTime.utc(2026, 1, 1), rssi: -40),
      RfidTag(epc: epc, readTime: DateTime.utc(2026, 1, 2), rssi: -41),
    ]);

    // Both reads produce a Tag (the batch preserves per-read entries), and the
    // second reuses the cached decode with the updated readTime.
    expect(result.tags, hasLength(2));
    expect(result.tags[0].barcode, '1234567890');
    expect(result.tags[1].barcode, '1234567890');
    expect(result.tags[1].readTime, DateTime.utc(2026, 1, 2));
  });

  test('GroupFilterStep passes tags matching the customer prefix', () async {
    final epc = encodeXcode('180005085L', 100);
    final pipeline = TagProcessingPipeline();
    pipeline.updateGroupSettings(_groupSettings(customerPrefixes: ['100']));

    final result = await pipeline.processBatch([readOf(epc)]);

    expect(result.tags, hasLength(1));
    expect(result.tags.single.tagData['companyPrefix'], '100');
  });

  test('GroupFilterStep filters out tags whose prefix does not match', () async {
    final epc = encodeXcode('180005085L', 100); // decodes to prefix "100"
    final pipeline = TagProcessingPipeline();
    pipeline.updateGroupSettings(_groupSettings(customerPrefixes: ['999']));

    final result = await pipeline.processBatch([readOf(epc)]);

    expect(result.tags, isEmpty);
  });

  test('undecodable EPC is skipped rather than crashing the batch', () async {
    final good = encodeXcode('00123', 1);
    final pipeline = TagProcessingPipeline();

    final result = await pipeline.processBatch([
      readOf('ZZZZ'), // not valid hex / wrong length → decode throws → skipped
      readOf(good),
    ]);

    expect(result.tags, hasLength(1));
    expect(result.tags.single.barcode, '00123');
  });
}

GroupSettings _groupSettings({
  List<String> barcodeStandards = const [],
  List<String> customerPrefixes = const [],
}) {
  return GroupSettings(
    barcodeStandards: barcodeStandards,
    customerPrefixes: customerPrefixes,
    prefixLength: 0,
    displayCatalogData: const [],
    displayCatalogDataOpt: const [],
    tagAccessPassword: '',
    useSmartZones: false,
    encodingStandard: EncodingStandard.xcode,
    customerXcodePrefix: 100,
  );
}
