import 'dart:convert';

import 'package:family_doc/core/network/api_config.dart';
import 'package:family_doc/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  // These tests exercise the real HTTP path, so they only run with the mock off.
  final skip = ApiConfig.useMockApi ? 'useMockApi is on' : null;

  test('reads OTP from response and verifies with 200', () async {
    final repo = AuthRepository(client: MockClient((req) async {
      if (req.url.path.endsWith(ApiConfig.sendOtp)) {
        return http.Response(jsonEncode({'otp': '4321'}), 200);
      }
      expect(jsonDecode(req.body)['otp'], '4321');
      return http.Response(jsonEncode({'token': 't'}), 200);
    }));
    final otp = await repo.sendOtp('9876543210');
    expect(otp, '4321');
    expect(await repo.verifyOtp('9876543210', otp), 't');
  }, skip: skip);

  test('non-200 throws AuthException', () async {
    final repo =
        AuthRepository(client: MockClient((_) async => http.Response('', 500)));
    expect(repo.sendOtp('9876543210'), throwsA(isA<AuthException>()));
  }, skip: skip);
}
