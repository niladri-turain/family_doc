import 'dart:convert';
import 'dart:io';

import 'package:family_doc/core/network/api_client.dart';
import 'package:family_doc/core/network/api_exception.dart';
import 'package:family_doc/core/storage/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TokenStorage tokens;
  late http.Request last;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    tokens = TokenStorage();
  });

  ApiClient client(int status, Object? body) => ApiClient(
    tokenStorage: tokens,
    baseUrl: 'https://test.local',
    client: MockClient((req) async {
      last = req;
      return http.Response(body == null ? '' : jsonEncode(body), status);
    }),
  );

  test('GET sends bearer token, no body, query params', () async {
    await tokens.saveTokens(accessToken: 'abc');
    final data = await client(200, {
      'ok': true,
    }).get('/api/v1/members', query: {'page': 1});
    expect(data, {'ok': true});
    expect(last.method, 'GET');
    expect(last.url.toString(), 'https://test.local/api/v1/members?page=1');
    expect(last.headers['Authorization'], 'Bearer abc');
    expect(last.body, isEmpty);
  });

  test('POST with auth:false sends JSON body without token', () async {
    await tokens.saveTokens(accessToken: 'abc');
    await client(200, {}).post('/x', body: {'a': 1}, auth: false);
    expect(last.method, 'POST');
    expect(jsonDecode(last.body), {'a': 1});
    expect(last.headers.containsKey('Authorization'), isFalse);
  });

  test('DELETE works and empty body returns null', () async {
    expect(await client(204, null).delete('/x/1'), isNull);
    expect(last.method, 'DELETE');
  });

  test('non-2xx throws ApiException with server message', () async {
    expect(
      client(400, {'message': 'Invalid OTP'}).post('/x'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.message, 'message', 'Invalid OTP')
            .having((e) => e.statusCode, 'status', 400),
      ),
    );
  });

  test('nested {"error": {"code","message"}} is parsed', () async {
    expect(
      client(409, {
        'error': {'code': 'SELF_EXISTS', 'message': 'Self exists'},
      }).post('/x'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.message, 'message', 'Self exists')
            .having((e) => e.code, 'code', 'SELF_EXISTS'),
      ),
    );
  });

  test('multipart sends fields and file with bearer token', () async {
    await tokens.saveTokens(accessToken: 'abc');
    final dir = await Directory.systemTemp.createTemp();
    final file = File('${dir.path}/p.jpg')..writeAsBytesSync([1, 2, 3]);
    late http.BaseRequest sent;
    late String raw;
    final api = ApiClient(
      tokenStorage: tokens,
      baseUrl: 'https://test.local',
      client: MockClient.streaming((req, stream) async {
        sent = req;
        raw = utf8.decode(await stream.toBytes(), allowMalformed: true);
        return http.StreamedResponse(
          Stream.value(utf8.encode('{"member":{}}')),
          201,
        );
      }),
    );
    await api.multipart(
      '/m',
      fields: {'fullName': 'A B'},
      files: {'photo': file.path},
    );
    expect(sent.headers['Authorization'], 'Bearer abc');
    expect(sent.headers['content-type'], startsWith('multipart/form-data'));
    expect(raw, contains('name="fullName"'));
    expect(raw, contains('name="photo"; filename="p.jpg"'));
    expect(raw, contains('content-type: image/jpeg'));
  });
}
