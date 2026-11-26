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
