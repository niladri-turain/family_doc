import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'models/saved_document.dart';

/// Where saved documents live. [HiveDocumentStore] on the phone;
/// tests pass an in-memory one to `setupLocator`.
abstract class DocumentStore {
  Future<List<SavedDocument>> loadAll();

  /// Copies [file] into app storage and saves its details.
  Future<SavedDocument> add({
    required XFile file,
    required String name,
    required int memberId,
    required int categoryId,
    required bool customCategory,
    int? typeId,
    String? typeName,
    DateTime? expiryDate,
    String? text,
  });

  /// Saves changed details (expiry date, read text) of a document.
  Future<SavedDocument> update(SavedDocument document);

  Future<void> remove(SavedDocument document);

  /// Changes the name and renames the file to match.
  Future<SavedDocument> rename(SavedDocument document, String name);

  /// Full path of the saved file on this phone.
  Future<String> pathOf(SavedDocument document);
}

/// Details in the Hive box "documents" (one map per document, keyed by id);
/// files in the app's documents folder, under documents/.
class HiveDocumentStore implements DocumentStore {
  static const _boxName = 'documents';

  Box<Map>? _box;
  Directory? _dir;

  Future<Box<Map>> _openBox() async {
    final box = _box;
    if (box != null) return box;
    await Hive.initFlutter();
    return _box = await Hive.openBox<Map>(_boxName);
  }

  Future<Directory> _files() async {
    final dir = _dir;
    if (dir != null) return dir;
    final root = await getApplicationDocumentsDirectory();
    final created = await Directory(
      '${root.path}/documents',
    ).create(recursive: true);
    return _dir = created;
  }

  @override
  Future<List<SavedDocument>> loadAll() async {
    final box = await _openBox();
    return box.values.map(SavedDocument.fromMap).toList();
  }

  @override
  Future<SavedDocument> add({
    required XFile file,
    required String name,
    required int memberId,
    required int categoryId,
    required bool customCategory,
    int? typeId,
    String? typeName,
    DateTime? expiryDate,
    String? text,
  }) async {
    final box = await _openBox();
    final dir = await _files();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final fileName = file.name.isNotEmpty
        ? file.name
        : file.path.split('/').last;
    final dot = fileName.lastIndexOf('.');
    final ext = dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
    final storedName = '$id/${SavedDocument.fileNameFor(name, ext)}';
    await Directory('${dir.path}/$id').create(recursive: true);
    await file.saveTo('${dir.path}/$storedName');
    final document = SavedDocument(
      id: id,
      memberId: memberId,
      categoryId: categoryId,
      customCategory: customCategory,
      typeId: typeId,
      typeName: typeName,
      name: name,
      fileName: fileName,
      storedName: storedName,
      size: await File('${dir.path}/$storedName').length(),
      createdAt: DateTime.now(),
      expiryDate: expiryDate,
      text: text,
    );
    await box.put(id, document.toMap());
    return document;
  }

  @override
  Future<SavedDocument> update(SavedDocument document) async {
    final box = await _openBox();
    await box.put(document.id, document.toMap());
    return document;
  }

  @override
  Future<void> remove(SavedDocument document) async {
    final box = await _openBox();
    await box.delete(document.id);
    final file = File(await pathOf(document));
    if (await file.exists()) await file.delete();
    final folder = Directory('${(await _files()).path}/${document.id}');
    if (await folder.exists()) await folder.delete(recursive: true);
  }

  @override
  Future<SavedDocument> rename(SavedDocument document, String name) async {
    final box = await _openBox();
    final dir = await _files();
    final storedName =
        '${document.id}/${SavedDocument.fileNameFor(name, document.extension)}';
    if (storedName != document.storedName) {
      await Directory('${dir.path}/${document.id}').create(recursive: true);
      final old = File('${dir.path}/${document.storedName}');
      if (await old.exists()) await old.rename('${dir.path}/$storedName');
    }
    final renamed = document.copyWith(name: name, storedName: storedName);
    await box.put(document.id, renamed.toMap());
    return renamed;
  }

  @override
  Future<String> pathOf(SavedDocument document) async =>
      '${(await _files()).path}/${document.storedName}';
}
