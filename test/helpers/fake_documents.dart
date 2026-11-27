import 'dart:ui';

import 'package:cross_file/cross_file.dart';
import 'package:family_doc/features/documents/data/document_store.dart';
import 'package:family_doc/features/documents/data/document_type_store.dart';
import 'package:family_doc/features/documents/data/models/document_type.dart';
import 'package:family_doc/features/documents/data/file_actions.dart';
import 'package:family_doc/features/documents/data/models/saved_document.dart';
import 'package:family_doc/features/documents/data/reading/document_reader.dart';
import 'package:family_doc/features/reminders/reminder_planner.dart';
import 'package:family_doc/features/reminders/reminder_service.dart';

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
    DateTime? expiryDate,
    String? text,
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
      expiryDate: expiryDate,
      text: text,
    );
    documents.add(document);
    return document;
  }

  @override
  Future<SavedDocument> update(SavedDocument document) async {
    documents[documents.indexWhere((d) => d.id == document.id)] = document;
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

/// Returns [next] as what was read from any picked file.
class FakeDocumentReader implements DocumentReader {
  DocumentScan? next;
  final read_ = <String>[];

  @override
  Future<DocumentScan?> read(XFile file) async {
    read_.add(file.name);
    return next;
  }
}

/// Records what would be scheduled instead of showing notifications.
class FakeReminderService implements ReminderService {
  List<PlannedReminder> scheduled = [];

  @override
  void Function(String? payload)? onTap;

  @override
  Future<void> init() async {}

  @override
  Future<String?> launchPayload() async => null;

  @override
  Future<void> schedule(List<PlannedReminder> reminders) async =>
      scheduled = reminders;
}

/// The user's own document types, in memory instead of Hive.
class MemoryDocumentTypeStore implements DocumentTypeStore {
  final types = <DocumentType>[];
  var _next = 0;

  @override
  Future<List<DocumentType>> loadAll() async => [...types];

  @override
  Future<DocumentType> add({
    required String name,
    required int categoryId,
    required bool customCategory,
  }) async {
    final type = DocumentType(
      id: -(++_next),
      name: name,
      categoryId: categoryId,
      customCategory: customCategory,
      isCustom: true,
    );
    types.add(type);
    return type;
  }

  @override
  Future<void> remove(DocumentType type) async =>
      types.removeWhere((t) => t.id == type.id);
}
