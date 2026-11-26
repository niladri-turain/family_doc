import 'dart:convert';

import 'package:family_doc/app.dart';
import 'package:family_doc/core/di/service_locator.dart';
import 'package:family_doc/core/routes/app_routes.dart';
import 'package:family_doc/core/storage/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// In-memory server that follows /api/v1/family-members from the API docs.
class FakeFamilyServer {
  final members = <Map<String, dynamic>>[];
  final requests = <http.Request>[];
  int _id = 0;

  late final client = MockClient((req) async {
    requests.add(req);
    expect(req.headers['Authorization'], 'Bearer tok');
    final segments = req.url.pathSegments;
    if (req.method == 'PATCH' && segments.length == 4) {
      final id = int.parse(segments.last);
      final i = members.indexWhere((m) => m['id'] == id);
      if (i < 0) return http.Response('', 404);
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      members[i] = {
        ...members[i],
        ...body,
        'mobile': body['mobile'] == null ? null : '+91${body['mobile']}',
      };
      return http.Response(jsonEncode({'member': members[i]}), 200);
    }
    if (!req.url.path.endsWith('/api/v1/family-members')) {
      return http.Response('', 404);
    }
    if (req.method == 'GET') {
      return http.Response(
        jsonEncode({'total': members.length, 'members': members}),
        200,
      );
    }
    final body = jsonDecode(req.body) as Map<String, dynamic>;
    if (body['relation'] == 'self' &&
        members.any((m) => m['relation'] == 'self')) {
      return http.Response(
        jsonEncode({
          'error': {
            'code': 'SELF_EXISTS',
            'message': 'You already have a self member',
          },
        }),
        409,
      );
    }
    final member = {
      'id': ++_id,
      ...body,
      if (body['mobile'] != null) 'mobile': '+91${body['mobile']}',
      'photoUrl': null,
      'createdAt': '2026-11-26T08:14:01.505Z',
    };
    members.add(member);
    return http.Response(jsonEncode({'member': member}), 201);
  });
}

Finder buttonWith(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
);

Future<FakeFamilyServer> start(
  WidgetTester tester, {
  List<Map<String, dynamic>> seed = const [],
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  FlutterSecureStorage.setMockInitialValues({});
  final server = FakeFamilyServer()..members.addAll(seed);
  await setupLocator(httpClient: server.client);
  await sl<TokenStorage>().saveTokens(accessToken: 'tok');
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const FamilyDocApp(initialRoute: AppRoutes.family));
  await tester.pumpAndSettle();
  return server;
}

Future<void> pickDateAndGender(WidgetTester tester) async {
  await tester.tap(find.text('DD / MM / YYYY'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Select'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Male').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty list: Add myself enabled, Add family member disabled', (
    tester,
  ) async {
    final server = await start(tester);
    expect(server.requests.single.method, 'GET');
    expect(find.text('No members yet'), findsOneWidget);
    expect(
      tester.widget<ButtonStyleButton>(buttonWith('Add myself')).enabled,
      isTrue,
    );
    expect(
      tester.widget<ButtonStyleButton>(buttonWith('Add family member')).enabled,
      isFalse,
    );
  });

  testWidgets('add self, then a family member through the API', (tester) async {
    final server = await start(tester);

    await tester.tap(find.text('Add myself'));
    await tester.pumpAndSettle();
    expect(find.text('Add yourself'), findsOneWidget);
    expect(find.text('Father'), findsNothing); // only Self is offered

    // Required fields
    await tester.tap(find.text('Save member'));
    await tester.pump();
    expect(find.text('Enter the full name'), findsOneWidget);
    expect(find.text('Choose date of birth'), findsOneWidget);
    expect(find.text('Choose gender'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Rahul Sharma');
    await pickDateAndGender(tester);
    await tester.enterText(find.byType(TextField).last, '9876543210');
    await tester.tap(find.text('Save member'));
    await tester.pumpAndSettle();

    final post = server.requests.last;
    expect(post.method, 'POST');
    final sent = jsonDecode(post.body) as Map<String, dynamic>;
    expect(sent['relation'], 'self');
    expect(sent['fullName'], 'Rahul Sharma');
    expect(sent['gender'], 'male');
    expect(sent['mobile'], '9876543210');
    expect(sent['dateOfBirth'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));

    expect(find.text('Self · 0 documents'), findsOneWidget);
    expect(find.text('1 member · 0 documents'), findsOneWidget);

    // Family member with +
    await tester.tap(find.byTooltip('Add member'));
    await tester.pumpAndSettle();
    expect(find.text('Self'), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'Sunil Sharma');
    await tester.tap(find.text('Father'));
    await pickDateAndGender(tester);
    await tester.tap(find.text('Save member'));
    await tester.pumpAndSettle();

    expect(jsonDecode(server.requests.last.body)['relation'], 'father');
    expect(find.text('Father · 0 documents'), findsOneWidget);
    expect(find.text('2 members · 0 documents'), findsOneWidget);
  });

  testWidgets('tap a member to edit it; PATCH updates the list', (
    tester,
  ) async {
    final server = await start(
      tester,
      seed: [
        {
          'id': 1,
          'relation': 'self',
          'fullName': 'Rahul Sharma',
          'dateOfBirth': '1996-08-12',
          'gender': 'male',
          'mobile': '+919876543210',
          'photoUrl': null,
        },
        {
          'id': 2,
          'relation': 'father',
          'fullName': 'Sunil Sharma',
          'dateOfBirth': '1966-01-01',
          'gender': 'male',
          'mobile': null,
          'photoUrl': null,
        },
      ],
    );

    // Self: prefilled, relation locked to Self
    await tester.tap(find.text('Rahul Sharma'));
    await tester.pumpAndSettle();
    expect(find.text('Edit my details'), findsOneWidget);
    expect(find.text('12 / 08 / 1996'), findsOneWidget);
    expect(find.text('9876543210'), findsOneWidget);
    expect(find.text('Father'), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'Rahul K Sharma');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    final patch = server.requests.last;
    expect(patch.method, 'PATCH');
    expect(patch.url.path, '/api/v1/family-members/1');
    final sent = jsonDecode(patch.body) as Map<String, dynamic>;
    expect(sent['fullName'], 'Rahul K Sharma');
    expect(sent['relation'], 'self');
    expect(sent['mobile'], '9876543210');
    expect(find.text('Rahul K Sharma'), findsOneWidget);

    // Family member: change relation, add a mobile
    await tester.tap(find.text('Sunil Sharma'));
    await tester.pumpAndSettle();
    expect(find.text('Edit member'), findsOneWidget);
    await tester.tap(find.text('Other'));
    await tester.enterText(find.byType(TextField).last, '9123456780');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    final sent2 = jsonDecode(server.requests.last.body) as Map<String, dynamic>;
    expect(sent2['relation'], 'other');
    expect(sent2['mobile'], '9123456780');
    expect(find.text('Other · 0 documents'), findsOneWidget);
  });
}
