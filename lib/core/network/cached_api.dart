import '../storage/api_cache.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// GET with an on-phone copy: a successful answer is saved under [key];
/// when the server can't be reached, the saved answer is used instead
/// (no copy yet → the network error is thrown as before).
/// Server errors (401, 404…) are never hidden.
Future<dynamic> getWithCache(
  ApiClient api,
  ApiCache cache,
  String key,
  String endpoint, {
  Map<String, dynamic>? query,
}) async {
  try {
    final data = await api.get(endpoint, query: query);
    await cache.write(key, data);
    return data;
  } on ApiException catch (e) {
    if (!e.isNetworkError) rethrow;
    final saved = await cache.read(key);
    if (saved == null) rethrow;
    return saved;
  }
}

/// Keeps a saved list answer (`{"<field>": [...]}`) in step after an add,
/// edit or delete, so it matches the server without fetching again.
Future<void> updateCachedList(
  ApiCache cache,
  String key,
  String field,
  List<dynamic> Function(List<dynamic> items) change,
) async {
  final saved = await cache.read(key);
  if (saved == null) return;
  final items = saved is Map ? saved[field] : saved;
  if (items is! List) return;
  final updated = change(List<dynamic>.of(items));
  await cache.write(key, saved is Map ? {...saved, field: updated} : updated);
}
