import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/token_storage.dart';
import 'api_endpoints.dart';
import 'api_logger.dart';
import 'api_exception.dart';

/// One place for every HTTP call.
///
/// ```dart
/// final data = await api.get(ApiEndpoints.members);
/// final data = await api.post(ApiEndpoints.verifyOtp, body: {...});
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
  })  : _tokens = tokenStorage,
        _client = client ?? http.Client(),
        _baseUrl = baseUrl;

  final TokenStorage _tokens;
  final http.Client _client;
  final String _baseUrl;

  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) =>
      _send('GET', endpoint, query: query, auth: auth);

  Future<dynamic> post(
    String endpoint, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) =>
      _send('POST', endpoint, body: body, query: query, auth: auth);

  Future<dynamic> put(
    String endpoint, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) =>
      _send('PUT', endpoint, body: body, query: query, auth: auth);

  Future<dynamic> delete(
    String endpoint, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) =>
      _send('DELETE', endpoint, body: body, query: query, auth: auth);

  Future<dynamic> _send(
    String method,
    String endpoint, {
    Object? body,
    Map<String, dynamic>? query,
    required bool auth,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );

    final request = http.Request(method, uri)
      ..headers.addAll(await _headers(auth));
    final sendBody = body != null && method != 'GET';
    if (sendBody) {
      request.body = jsonEncode(body);
    }
    ApiLogger.request(
      method: method,
      url: uri,
      headers: request.headers,
      body: sendBody ? body : null,
    );

    final watch = Stopwatch()..start();
    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(ApiEndpoints.timeout),
      );
    } on TimeoutException catch (e) {
      ApiLogger.error(method: method, url: uri, error: e);
      throw const ApiException('The server took too long. Please try again.');
    } catch (e) {
      // SocketException / ClientException: no internet or server down.
      ApiLogger.error(method: method, url: uri, error: e);
      throw const ApiException(
          "Couldn't reach the server. Check your internet and try again.");
    }

    ApiLogger.response(
      method: method,
      url: uri,
      statusCode: response.statusCode,
      took: watch.elapsed,
      body: response.body,
    );
    return _handle(response);
  }

  Future<Map<String, String>> _headers(bool auth) async {
    final headers = {
      'Content-Type': 'application/json',
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

    final serverMessage = data is Map
        ? (data['message'] ?? data['error'])?.toString()
        : null;
    throw ApiException(
      serverMessage ?? 'Something went wrong (code ${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }
}
