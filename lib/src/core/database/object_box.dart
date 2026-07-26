import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../objectbox.g.dart';
import '../../features/catalog/domain/catalog_item.dart';

class ObjectBox {
  ObjectBox._(this.store);

  /// Bump when the on-disk schema changes so the stamp-file check wipes the old
  /// database on first launch (avoids an ObjectBox schema-mismatch crash).
  /// v8: replaced the seeded `Product` entity with the sync-populated
  /// `CatalogItem` entity.
  static const _seedVersion = 8;

  final Store store;
  late final Box<CatalogItem> catalogItems = store.box<CatalogItem>();

  static Future<ObjectBox> create() async {
    final docs = await getApplicationDocumentsDirectory();
    final dbDir = Directory('${docs.path}/objectbox');
    final stamp = File('${docs.path}/objectbox.version');

    final stampValue = stamp.existsSync() ? stamp.readAsStringSync() : '';
    if (stampValue != '$_seedVersion' && dbDir.existsSync()) {
      dbDir.deleteSync(recursive: true);
    }

    final store = await openStore(directory: dbDir.path);
    final ob = ObjectBox._(store);
    stamp.writeAsStringSync('$_seedVersion');
    return ob;
  }
}
