import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'models/document_category.dart';

/// Category API calls. The bearer token is added by [ApiClient].
class CategoryService {
  CategoryService(this._api);

  final ApiClient _api;

  /// GET /api/v1/categories → {"categories": [...]}, sorted by id.
  Future<List<DocumentCategory>> getCategories() async {
    final data = await _api.get(ApiEndpoints.categories);
    final list = (data is Map ? data['categories'] : data) as List? ?? const [];
    return list
        .map((e) => DocumentCategory.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }
}
