import 'dart:ui';

import 'package:cross_file/cross_file.dart';
import 'package:family_doc/features/documents/data/document_store.dart';
import 'package:family_doc/features/documents/data/file_actions.dart';
import 'package:family_doc/features/documents/data/models/saved_document.dart';

/// Keeps documents in memory instead of Hive + the documents folder.
class MemoryDocumentStore implements DocumentStore {
  final documents = <SavedDocument>[];
  var _next = 0;

  @override
  Future<List<SavedDocument>> loadAll() async => [...documents];

  @override
  Future<SavedDocument> add({
    required XFile file,
    required String name,
    required int memberId,
    required int categoryId,
    required bool customCategory,
    int? typeId,
    String? typeName,
  }) async {
    final id = '${++_next}';
    final document = SavedDocument(
      id: id,
      memberId: memberId,
      categoryId: categoryId,
      customCategory: customCategory,
      typeId: typeId,
      typeName: typeName,
      name: name,
      fileName: file.name,
      storedName: '$id/${SavedDocument.fileNameFor(name, _ext(file.name))}',
      size: await file.length(),
      createdAt: DateTime.now(),
    );
    documents.add(document);
    return document;
  }

  @override
  Future<void> remove(SavedDocument document) async =>
      documents.removeWhere((d) => d.id == document.id);

  @override
  Future<SavedDocument> rename(SavedDocument document, String name) async {
    final renamed = document.copyWith(
      name: name,
      storedName:
          '${document.id}/${SavedDocument.fileNameFor(name, document.extension)}',
    );
    documents[documents.indexWhere((d) => d.id == document.id)] = renamed;
    return renamed;
  }

  static String _ext(String name) =>
      name.contains('.') ? name.split('.').last.toLowerCase() : '';

  @override
  Future<String> pathOf(SavedDocument document) async =>
      '/docs/${document.storedName}';
}

/// Returns [nextFile] when picking and records opens and shares.
class FakeFileActions implements FileActions {
  XFile? nextFile;
  final picked = <FileSource>[];
  final opened = <String>[];
  final shared = <String>[];

  @override
  Future<XFile?> pick(FileSource source) async {
    picked.add(source);
    return nextFile;
  }

  @override
  Future<String?> open(String path) async {
    opened.add(path);
    return null;
  }

  @override
  Future<void> share(String path, {required String name, Rect? origin}) async =>
      shared.add(path);

  @override
  Future<void> shareAll(List<String> paths, {Rect? origin}) async =>
      shared.addAll(paths);
}
