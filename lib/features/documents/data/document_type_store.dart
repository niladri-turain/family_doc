import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'models/document_type.dart';

/// Document types the user added themselves (no server API), kept on the
/// phone so they are still there after the app restarts.
/// [HiveDocumentTypeStore] on the phone; tests pass an in-memory one.
abstract class DocumentTypeStore {
  Future<List<DocumentType>> loadAll();

  Future<DocumentType> add({
    required String name,
    required int categoryId,
    required bool customCategory,
  });

  Future<void> remove(DocumentType type);
}

/// Hive box "document_types": one map per type, keyed by its id.
class HiveDocumentTypeStore implements DocumentTypeStore {
  static const _boxName = 'document_types';

  Box<Map>? _box;

  Future<Box<Map>> _openBox() async {
    final box = _box;
    if (box != null) return box;
    await Hive.initFlutter();
    return _box = await Hive.openBox<Map>(_boxName);
  }

  @override
  Future<List<DocumentType>> loadAll() async {
    final box = await _openBox();
    return box.values.map(DocumentType.fromMap).toList();
  }

  @override
  Future<DocumentType> add({
    required String name,
    required int categoryId,
    required bool customCategory,
  }) async {
    final box = await _openBox();
    // Negative, so it never matches a server type id.
    final type = DocumentType(
      id: -DateTime.now().microsecondsSinceEpoch,
      name: name,
      categoryId: categoryId,
      customCategory: customCategory,
      isCustom: true,
    );
    await box.put('${type.id}', type.toMap());
    return type;
  }

  @override
  Future<void> remove(DocumentType type) async {
    final box = await _openBox();
    await box.delete('${type.id}');
  }
}
