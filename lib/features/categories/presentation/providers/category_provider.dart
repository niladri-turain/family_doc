import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/category_service.dart';
import '../../data/models/document_category.dart';

/// Document categories state, read with `context.watch<CategoryProvider>()`.
class CategoryProvider extends ChangeNotifier {
  CategoryProvider({required CategoryService service}) : _service = service;

  final CategoryService _service;

  List<DocumentCategory> _categories = [];
  List<DocumentCategory> get categories => _categories;

  bool _hasLoaded = false;
  bool get hasLoaded => _hasLoaded;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ApiException? _error;
  ApiException? get error => _error;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  /// POST a new user category; it is added at the end of the grid.
  /// Throws [ApiException] with the server message (e.g. name already exists).
  Future<DocumentCategory> addCategory({
    required String name,
    String? description,
  }) async {
    _isSaving = true;
    notifyListeners();
    try {
      final category = await _service.addCategory(
        name: name.trim(),
        description: description?.trim(),
      );
      _categories = [..._categories, category];
      return category;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// PATCH one of the user's own categories (global ones can't be changed).
  Future<DocumentCategory> updateCategory(
    DocumentCategory category, {
    required String name,
    String? description,
  }) async {
    assert(category.isCustom, 'Only your own categories can be edited');
    _isSaving = true;
    notifyListeners();
    try {
      final updated = await _service.updateCategory(
        category.id,
        name: name.trim(),
        description: description?.trim(),
      );
      _categories = [
        for (final c in _categories) _same(c, category) ? updated : c,
      ];
      return updated;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// DELETE one of the user's own categories. A 404 (already gone) also
  /// removes it here; other errors are rethrown.
  Future<void> deleteCategory(DocumentCategory category) async {
    assert(category.isCustom, 'Only your own categories can be deleted');
    try {
      await _service.deleteCategory(category.id);
    } on ApiException catch (e) {
      if (e.statusCode != 404) rethrow;
    }
    _categories = _categories.where((c) => !_same(c, category)).toList();
    notifyListeners();
  }

  /// Global and custom ids can overlap, so compare both.
  static bool _same(DocumentCategory a, DocumentCategory b) =>
      a.id == b.id && a.isCustom == b.isCustom;

  int get totalDocuments =>
      _categories.fold(0, (sum, c) => sum + c.documentCount);

  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _categories = await _service.getCategories();
      _hasLoaded = true;
    } on ApiException catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _categories = [];
    _hasLoaded = false;
    _error = null;
    notifyListeners();
  }
}
