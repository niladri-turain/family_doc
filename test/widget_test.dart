import 'dart:convert';

import 'package:family_doc/app.dart';
import 'package:family_doc/core/di/service_locator.dart';
import 'package:family_doc/core/storage/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'helpers/fake_documents.dart';

/// Fake backend matching the Postman responses.
MockClient fakeBackend({bool verifyFails = false}) => MockClient((req) async {
  if (req.url.path.endsWith('/otp/request')) {
    expect(jsonDecode(req.body)['mobile'], '9876543210');
    return http.Response(
      jsonEncode({
        'message': 'OTP sent',
        'expiresInSeconds': 300,
        'devOtp': '768598',
      }),
      200,
    );
  }
  if (req.url.path.endsWith('/otp/verify')) {
    final body = jsonDecode(req.body);
    expect(body['otp'], '768598');
    if (verifyFails) {
      return http.Response(jsonEncode({'message': 'Invalid OTP'}), 400);
    }
    return http.Response(
      jsonEncode({
        'user': {
          'id': 1,
          'mobile': '+919876543210',
          'createdAt': '2026-11-25T12:59:41.852Z',
        },
        'isNewUser': false,
        'accessToken': 'token-123',
        'refreshToken': 'refresh-456',
        'tokenType': 'Bearer',
        'expiresIn': '24h',
      }),
      200,
    );
  }
  if (req.url.path.endsWith('/family-members')) {
    expect(req.headers['Authorization'], 'Bearer token-123');
    return http.Response(jsonEncode({'total': 0, 'members': []}), 200);
  }
  return http.Response('', 404);
});

Future<void> openLogin(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const FamilyDocApp());
  await tester.tap(find.text('Get started'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('invalid number shows error', (tester) async {
    await setupLocator(
      httpClient: fakeBackend(),
      documentStore: MemoryDocumentStore(),
      fileActions: FakeFileActions(),
    );
    await openLogin(tester);
    await tester.enterText(find.byType(TextField), '12345');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Enter a valid 10-digit mobile number'), findsOneWidget);
  });

  testWidgets('both APIs succeed → token saved → My Family', (tester) async {
    await setupLocator(
      httpClient: fakeBackend(),
      documentStore: MemoryDocumentStore(),
      fileActions: FakeFileActions(),
    );
    await openLogin(tester);
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('No members yet'), findsOneWidget);
    expect(await sl<TokenStorage>().accessToken, 'token-123');
    expect(await sl<TokenStorage>().refreshToken, 'refresh-456');
  });

  testWidgets('verify fails → back to login with server message', (
    tester,
  ) async {
    await setupLocator(
      httpClient: fakeBackend(verifyFails: true),
      documentStore: MemoryDocumentStore(),
      fileActions: FakeFileActions(),
    );
    await openLogin(tester);
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't sign you in"), findsOneWidget);
    expect(find.text('Invalid OTP'), findsOneWidget);
    expect(await sl<TokenStorage>().hasToken, isFalse);
  });
}
