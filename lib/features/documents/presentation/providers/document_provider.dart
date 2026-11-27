import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';

import '../../../categories/data/models/document_category.dart';
import '../../data/document_store.dart';
import '../../data/document_type_store.dart';
import '../../data/models/document_type.dart';
import '../../data/models/saved_document.dart';

/// Documents saved on this phone, per member and category.
/// Read with `context.watch<DocumentProvider>()`.
class DocumentProvider extends ChangeNotifier {
  DocumentProvider({
    required DocumentStore store,
    required DocumentTypeStore typeStore,
  }) : _store = store,
       _typeStore = typeStore;

  final DocumentStore _store;
  final DocumentTypeStore _typeStore;

  /// Types the user added, oldest first.
  List<DocumentType> _customTypes = [];

  List<SavedDocument> _documents = [];

  /// Every saved document, newest first (chat and reminders read these).
  List<SavedDocument> get all => List.unmodifiable(_documents);

  bool _hasLoaded = false;
  bool get hasLoaded => _hasLoaded;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Future<void> load() async {
    try {
      _documents = await _store.loadAll()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('Could not read saved documents: $e');
    }
    try {
      _customTypes = await _typeStore.loadAll()
        // Ids are minus the creation time: oldest first.
        ..sort((a, b) => b.id.compareTo(a.id));
    } catch (e) {
      debugPrint('Could not read your document types: $e');
    }
    _hasLoaded = true;
    notifyListeners();
  }

  static bool _inCategory(SavedDocument d, DocumentCategory c) =>
      d.categoryId == c.id && d.customCategory == c.isCustom;

  /// Newest first.
  List<SavedDocument> documentsFor(int? memberId, DocumentCategory category) =>
      [
        for (final d in _documents)
          if (d.memberId == memberId && _inCategory(d, category)) d,
      ];

  int countFor(int? memberId, DocumentCategory category) =>
      documentsFor(memberId, category).length;

  int totalFor(int? memberId) =>
      _documents.where((d) => d.memberId == memberId).length;

  Future<SavedDocument> add({
    required XFile file,
    required String name,
    required int memberId,
    required DocumentCategory category,
    DocumentType? type,
    DateTime? expiryDate,
    String? text,
  }) async {
    _isSaving = true;
    notifyListeners();
    try {
      final document = await _store.add(
        file: file,
        name: name.trim(),
        memberId: memberId,
        categoryId: category.id,
        customCategory: category.isCustom,
        typeId: type?.id,
        typeName: type?.name,
        expiryDate: expiryDate,
        text: text,
      );
      _documents = [document, ..._documents];
      return document;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Sets (or with null, removes) the expiry date.
  Future<SavedDocument> setExpiry(SavedDocument document, DateTime? date) =>
      _replace(
        date == null
            ? document.copyWith(clearExpiry: true)
            : document.copyWith(expiryDate: date),
      );

  Future<SavedDocument> _replace(SavedDocument document) async {
    final saved = await _store.update(document);
    _documents = [for (final d in _documents) d.id == saved.id ? saved : d];
    notifyListeners();
    return saved;
  }

  Future<void> remove(SavedDocument document) async {
    await _store.remove(document);
    _documents = _documents.where((d) => d.id != document.id).toList();
    notifyListeners();
  }

  Future<SavedDocument> rename(SavedDocument document, String name) async {
    final renamed = await _store.rename(document, name.trim());
    _documents = [
      for (final d in _documents) d.id == document.id ? renamed : d,
    ];
    notifyListeners();
    return renamed;
  }

  /// When a member or one of the user's categories is deleted, its
  /// files go too.
  Future<void> removeWhere(bool Function(SavedDocument) test) async {
    for (final d in _documents.where(test).toList()) {
      await _store.remove(d);
    }
    _documents = _documents.where((d) => !test(d)).toList();
    notifyListeners();
  }

  Future<void> removeForMember(int memberId) =>
      removeWhere((d) => d.memberId == memberId);

  Future<void> removeForCategory(DocumentCategory category) =>
      removeWhere((d) => _inCategory(d, category));

  Future<String> pathOf(SavedDocument document) => _store.pathOf(document);

  /// The user's own types for [category], in the order they were added.
  List<DocumentType> customTypesFor(DocumentCategory category) => [
    for (final t in _customTypes)
      if (t.categoryId == category.id && t.customCategory == category.isCustom)
        t,
  ];

  /// Adds a type the user typed; it stays after the app restarts.
  Future<DocumentType> addCustomType(
    DocumentCategory category,
    String name,
  ) async {
    final type = await _typeStore.add(
      name: name.trim(),
      categoryId: category.id,
      customCategory: category.isCustom,
    );
    _customTypes = [..._customTypes, type];
    notifyListeners();
    return type;
  }

  /// Removes one of the user's types. Documents keep their type name.
  Future<void> removeCustomType(DocumentType type) async {
    await _typeStore.remove(type);
    _customTypes = _customTypes.where((t) => t.id != type.id).toList();
    notifyListeners();
  }
}
