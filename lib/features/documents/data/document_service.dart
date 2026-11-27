import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/cached_api.dart';
import '../../../core/storage/api_cache.dart';
import 'models/document_type.dart';

/// Document API calls. The bearer token is added by [ApiClient].
/// Types are saved on the phone per category and used when offline.
class DocumentService {
  DocumentService(this._api, this._cache);

  final ApiClient _api;
  final ApiCache _cache;

  /// GET /api/v1/document-types?categoryId={id} → {"documentTypes": [...]}
  /// Only active types, in the server's sortOrder.
  Future<List<DocumentType>> getDocumentTypes(int categoryId) async {
    final data = await getWithCache(
      _api,
      _cache,
      'document-types/$categoryId',
      ApiEndpoints.documentTypes,
      query: {'categoryId': '$categoryId'},
    );
    final list =
        (data is Map ? data['documentTypes'] : data) as List? ?? const [];
    return list
        .map((e) => DocumentType.fromJson(e as Map<String, dynamic>))
        .where((t) => t.isActive && t.name.isNotEmpty)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
}
