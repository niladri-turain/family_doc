import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../storage/token_storage.dart';
import 'api_endpoints.dart';
import 'api_logger.dart';
import 'api_exception.dart';
import 'connection_status.dart';

/// One place for every HTTP call.
///
/// ```dart
/// final data = await api.get(ApiEndpoints.familyMembers);
/// final data = await api.post(ApiEndpoints.verifyOtp, body: {...});
/// final data = await api.multipart(ApiEndpoints.familyMembers,
///     fields: {...}, files: {'photo': path});
/// ```
/// - `endpoint` is the path after the base URL.
/// - `body` is JSON-encoded (GET has no body; use `query` instead).
/// - The saved access token is sent as `Authorization: Bearer <token>`
///   unless `auth: false`.
/// - Returns the decoded JSON (Map / List), or null for an empty body.
/// - Throws [ApiException] for non-2xx responses and network problems.
class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    http.Client? client,
    String baseUrl = ApiEndpoints.baseUrl,
    ConnectionStatus? status,
  }) : _tokens = tokenStorage,
       _client = client ?? http.Client(),
       _baseUrl = baseUrl,
       _status = status;

  final TokenStorage _tokens;
  final ConnectionStatus? _status;
  final http.Client _client;
  final String _baseUrl;

  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) => _send('GET', endpoint, query: query, auth: auth);

  Future<dynamic> post(
    String endpoint, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) => _send('POST', endpoint, body: body, query: query, auth: auth);

  Future<dynamic> put(
    String endpoint, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) => _send('PUT', endpoint, body: body, query: query, auth: auth);

  Future<dynamic> patch(
    String endpoint, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) => _send('PATCH', endpoint, body: body, query: query, auth: auth);

  Future<dynamic> delete(
    String endpoint, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) => _send('DELETE', endpoint, body: body, query: query, auth: auth);

  /// Sends text [fields] plus files as multipart/form-data (e.g. a photo).
  /// [files] maps the form field name to a local file path.
  Future<dynamic> multipart(
    String endpoint, {
    String method = 'POST',
    Map<String, String> fields = const {},
    Map<String, String> files = const {},
    bool auth = true,
  }) async {
    final uri = _uri(endpoint, null);
    final request = http.MultipartRequest(method, uri)
      ..headers.addAll(await _headers(auth, json: false))
      ..fields.addAll(fields);
    for (final entry in files.entries) {
      request.files.add(
        await http.MultipartFile.fromPath(
          entry.key,
          entry.value,
          contentType: _mediaType(entry.value),
        ),
      );
    }
    return _execute(
      request,
      logBody: {
        ...fields,
        for (final e in files.entries)
          e.key: '<file ${e.value.split('/').last}>',
      },
    );
  }

  Future<dynamic> _send(
    String method,
    String endpoint, {
    Object? body,
    Map<String, dynamic>? query,
    required bool auth,
  }) async {
    final request = http.Request(method, _uri(endpoint, query))
      ..headers.addAll(await _headers(auth));
    final sendBody = body != null && method != 'GET';
    if (sendBody) {
      request.body = jsonEncode(body);
    }
    return _execute(request, logBody: sendBody ? body : null);
  }

  Uri _uri(String endpoint, Map<String, dynamic>? query) => Uri.parse(
    '$_baseUrl$endpoint',
  ).replace(queryParameters: query?.map((k, v) => MapEntry(k, '$v')));

  Future<dynamic> _execute(http.BaseRequest request, {Object? logBody}) async {
    final method = request.method;
    final uri = request.url;
    ApiLogger.request(
      method: method,
      url: uri,
      headers: request.headers,
      body: logBody,
    );

    final watch = Stopwatch()..start();
    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(ApiEndpoints.timeout),
      );
    } on TimeoutException catch (e) {
      ApiLogger.error(method: method, url: uri, error: e);
      _status?.update(offline: true);
      throw const ApiException('The server took too long. Please try again.');
    } catch (e) {
      // SocketException / ClientException: no internet or server down.
      ApiLogger.error(method: method, url: uri, error: e);
      _status?.update(offline: true);
      throw const ApiException(
        "You're offline. This needs internet. Please connect and try again.",
      );
    }
    _status?.update(offline: false);

    ApiLogger.response(
      method: method,
      url: uri,
      statusCode: response.statusCode,
      took: watch.elapsed,
      body: response.body,
    );
    return _handle(response);
  }

  static MediaType _mediaType(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      'pdf' => MediaType('application', 'pdf'),
      _ => MediaType('image', 'jpeg'),
    };
  }

  Future<Map<String, String>> _headers(bool auth, {bool json = true}) async {
    final headers = {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await _tokens.accessToken;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  dynamic _handle(http.Response response) {
    dynamic data;
    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } on FormatException {
        data = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return data;

    // Server errors look like {"error": {"code": "SELF_EXISTS", "message": "..."}}
    String? serverMessage;
    String? code;
    if (data is Map) {
      final error = data['error'];
      if (error is Map) {
        serverMessage = error['message']?.toString();
        code = error['code']?.toString();
      } else {
        serverMessage = (data['message'] ?? error)?.toString();
      }
    }
    throw ApiException(
      serverMessage ?? 'Something went wrong (code ${response.statusCode}).',
      statusCode: response.statusCode,
      code: code,
    );
  }
}
