import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'models/document_category.dart';

/// Category API calls. The bearer token is added by [ApiClient].
class CategoryService {
  CategoryService(this._api);

  final ApiClient _api;

  /// Global categories (sorted by id) followed by the user's own ones
  /// (oldest first). Both lists are fetched at the same time.
  Future<List<DocumentCategory>> getCategories() async {
    final results = await Future.wait([
      _api.get(ApiEndpoints.categories),
      _api.get(ApiEndpoints.userCategories),
    ]);
    return [
      ..._parse(results[0], isCustom: false),
      ..._parse(results[1], isCustom: true),
    ];
  }

  /// POST /api/v1/user-categories {"name", "description"} → {"category"}
  Future<DocumentCategory> addCategory({
    required String name,
    String? description,
  }) async {
    final data = await _api.post(
      ApiEndpoints.userCategories,
      body: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    return DocumentCategory.fromJson(
      (data as Map<String, dynamic>)['category'] as Map<String, dynamic>,
      isCustom: true,
    );
  }

  /// PATCH /api/v1/user-categories/{id} → {"category"}
  /// An empty description is sent as null to clear it.
  Future<DocumentCategory> updateCategory(
    int id, {
    required String name,
    String? description,
  }) async {
    final data = await _api.patch(
      ApiEndpoints.userCategory(id),
      body: {
        'name': name,
        'description': (description == null || description.isEmpty)
            ? null
            : description,
      },
    );
    return DocumentCategory.fromJson(
      (data as Map<String, dynamic>)['category'] as Map<String, dynamic>,
      isCustom: true,
    );
  }

  /// DELETE /api/v1/user-categories/{id} → 204
  Future<void> deleteCategory(int id) =>
      _api.delete(ApiEndpoints.userCategory(id));

  /// {"categories": [...]} → sorted by id.
  static List<DocumentCategory> _parse(dynamic data, {required bool isCustom}) {
    final list = (data is Map ? data['categories'] : data) as List? ?? const [];
    return list
        .map(
          (e) => DocumentCategory.fromJson(
            e as Map<String, dynamic>,
            isCustom: isCustom,
          ),
        )
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }
}
