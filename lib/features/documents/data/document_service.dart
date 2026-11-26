import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'models/document_type.dart';

/// Document API calls. The bearer token is added by [ApiClient].
class DocumentService {
  DocumentService(this._api);

  final ApiClient _api;

  /// GET /api/v1/document-types?categoryId={id} → {"documentTypes": [...]}
  /// Only active types, in the server's sortOrder.
  Future<List<DocumentType>> getDocumentTypes(int categoryId) async {
    final data = await _api.get(
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
