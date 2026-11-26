import 'dart:convert';

import 'package:family_doc/app.dart';
import 'package:family_doc/core/di/service_locator.dart';
import 'package:family_doc/core/routes/app_routes.dart';
import 'package:family_doc/core/storage/token_storage.dart';
import 'package:family_doc/core/widgets/dashed_border_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Fake server for /users/me, /family-members and /auth/logout.
class FakeServer {
  final members = <Map<String, dynamic>>[
    {
      'id': 3,
      'relation': 'self',
      'fullName': 'Rahul Sharma',
      'dateOfBirth': '1996-08-12',
      'gender': 'male',
      'photoUrl': null,
    },
    {
      'id': 4,
      'relation': 'father',
      'fullName': 'Sunil Sharma',
      'dateOfBirth': '1966-01-01',
      'gender': 'male',
      'photoUrl': null,
    },
  ];
  final userCategories = <Map<String, dynamic>>[];
  final calls = <String>[];

  late final client = MockClient((req) async {
    calls.add('${req.method} ${req.url.path}');
    final path = req.url.path;
    if (path == '/api/v1/users/me') {
      return http.Response(
        jsonEncode({
          'user': {'id': 1, 'mobile': '+919876543210'},
        }),
        200,
      );
    }
    if (path == '/api/v1/family-members') {
      return http.Response(
        jsonEncode({'total': members.length, 'members': members}),
        200,
      );
    }
    if (req.method == 'DELETE' && path.startsWith('/api/v1/family-members/')) {
      final id = int.parse(path.split('/').last);
      members.removeWhere((m) => m['id'] == id);
      return http.Response('', 204);
    }
    if (path == '/api/v1/categories') {
      return http.Response(
        jsonEncode({
          'categories': [
            {'id': 3, 'name': 'Assets', 'description': 'Property,Vehicle'},
            {'id': 1, 'name': 'Education', 'description': 'Marksheet,Degree'},
            {'id': 2, 'name': 'Government', 'description': 'Aadhaar,Pan,Voter'},
            {'id': 5, 'name': 'Health', 'description': 'Reports,Insurance'},
          ],
        }),
        200,
      );
    }
    if (path.startsWith('/api/v1/user-categories/')) {
      final id = int.parse(path.split('/').last);
      final i = userCategories.indexWhere((c) => c['id'] == id);
      if (i < 0) return http.Response('', 404);
      if (req.method == 'DELETE') {
        userCategories.removeAt(i);
        return http.Response('', 204);
      }
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      userCategories[i] = {...userCategories[i], ...body};
      return http.Response(jsonEncode({'category': userCategories[i]}), 200);
    }
    if (path == '/api/v1/user-categories') {
      if (req.method == 'POST') {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        if (userCategories.any((c) => c['name'] == body['name'])) {
          return http.Response(
            jsonEncode({
              'error': {
                'code': 'CATEGORY_EXISTS',
                'message': 'A category with this name already exists',
              },
            }),
            409,
          );
        }
        final category = {'id': userCategories.length + 1, ...body};
        userCategories.add(category);
        return http.Response(jsonEncode({'category': category}), 201);
      }
      return http.Response(jsonEncode({'categories': userCategories}), 200);
    }
    if (path == '/api/v1/auth/logout') {
      expect(jsonDecode(req.body)['refreshToken'], 'ref');
      return http.Response('', 204);
    }
    return http.Response('', 404);
  });
}

Future<FakeServer> openProfile(
  WidgetTester tester, {
  FakeServer? server,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  FlutterSecureStorage.setMockInitialValues({});
  // package_info_plus
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/package_info'),
        (_) async => {
          'appName': 'family_doc',
          'packageName': 'x',
          'version': '1.0.0',
          'buildNumber': '1',
        },
      );
  server ??= FakeServer();
  await setupLocator(httpClient: server.client);
  await sl<TokenStorage>().saveTokens(accessToken: 'tok', refreshToken: 'ref');
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const FamilyDocApp(initialRoute: AppRoutes.profile));
  await tester.pumpAndSettle();
  return server;
}

void main() {
  testWidgets('shows phone, Self name and version', (tester) async {
    await openProfile(tester);
    expect(find.text('+91 98765 43210'), findsOneWidget);
    expect(find.text('Rahul Sharma'), findsOneWidget);
    expect(find.text('Version 1.0.0 (1)'), findsOneWidget);
    expect(find.text('2 members in your family'), findsOneWidget);
  });

  testWidgets('delete member asks first, then calls DELETE', (tester) async {
    final server = await openProfile(tester);
    await tester.tap(find.text('Delete member'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete Sunil Sharma'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Sunil Sharma?'), findsOneWidget);

    // Cancel keeps the member
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(server.calls.where((c) => c.startsWith('DELETE')), isEmpty);

    await tester.tap(find.byTooltip('Delete Sunil Sharma'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(server.calls, contains('DELETE /api/v1/family-members/4'));
    expect(find.text('Sunil Sharma'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('log out asks first, revokes token, goes to Welcome', (
    tester,
  ) async {
    final server = await openProfile(tester);
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log out'));
    await tester.pumpAndSettle();

    expect(server.calls, contains('POST /api/v1/auth/logout'));
    expect(await sl<TokenStorage>().hasToken, isFalse);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('bottom navigation switches tabs without a back arrow', (
    tester,
  ) async {
    await openProfile(tester);
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('Family'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sunil Sharma'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('Dashboard'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Total documents'), findsOneWidget);
    expect(find.text('Education'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('Profile'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Version 1.0.0 (1)'), findsOneWidget);
  });

  testWidgets(
    'dashboard: categories from the API, Self selected, switch member',
    (tester) async {
      final server = await openProfile(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(BottomNavigationBar),
          matching: find.text('Dashboard'),
        ),
      );
      await tester.pumpAndSettle();

      expect(server.calls, contains('GET /api/v1/categories'));
      // Sorted by id: Education, Government, Assets, Health
      final names = ['Education', 'Government', 'Assets', 'Health'];
      final ys = [for (final n in names) tester.getTopLeft(find.text(n)).dy];
      expect(ys[0], ys[1]);
      expect(ys[2], ys[3]);
      expect(ys[2], greaterThan(ys[0]));
      expect(find.text('No documents'), findsNWidgets(4));
      expect(find.text('in 4 categories'), findsOneWidget);
      expect(find.text('Nothing uploaded yet'), findsOneWidget);

      // Self is selected by default
      expect(find.text('Rahul Sharma'), findsOneWidget);
      expect(find.text('Sunil Sharma'), findsNothing);

      await tester.tap(find.text('Rahul Sharma'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sunil Sharma'));
      await tester.pumpAndSettle();
      expect(find.text('Sunil Sharma'), findsOneWidget);
      expect(find.text('Rahul Sharma'), findsNothing);
    },
  );

  testWidgets('add category: POST user-categories, card appears, count grows', (
    tester,
  ) async {
    final server = await openProfile(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('Dashboard'),
      ),
    );
    await tester.pumpAndSettle();
    expect(server.calls, contains('GET /api/v1/user-categories'));
    expect(find.text('in 4 categories'), findsOneWidget);

    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    expect(find.text('New category'), findsOneWidget);

    // Name is required
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add category'));
    await tester.pump();
    expect(find.text('Enter a category name'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Papa');
    await tester.enterText(find.byType(TextField).last, 'Old papers');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add category'));
    await tester.pumpAndSettle();

    expect(server.calls, contains('POST /api/v1/user-categories'));
    expect(server.userCategories.single['name'], 'Papa');
    expect(server.userCategories.single['description'], 'Old papers');
    expect(find.text('New category'), findsNothing); // sheet closed
    expect(find.text('Papa'), findsOneWidget);
    expect(find.text('in 5 categories'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    // Same name again → server error shown under the name field
    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Papa');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add category'));
    await tester.pumpAndSettle();
    expect(
      find.text('A category with this name already exists'),
      findsOneWidget,
    );
    expect(find.text('New category'), findsOneWidget);
  });

  testWidgets('only custom categories can be edited and deleted', (
    tester,
  ) async {
    final server = FakeServer();
    server.userCategories.add({
      'id': 1,
      'name': 'Papa',
      'description': 'Old papers',
    });
    await openProfile(tester, server: server);
    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('Dashboard'),
      ),
    );
    await tester.pumpAndSettle();

    // Dotted border + menu only on the user's category
    expect(
      find.ancestor(
        of: find.text('Papa'),
        matching: find.byType(DashedBorderBox),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.text('Education'),
        matching: find.byType(DashedBorderBox),
      ),
      findsNothing,
    );
    expect(find.byTooltip('Edit or delete Papa'), findsOneWidget);
    expect(find.byTooltip('Edit or delete Education'), findsNothing);
    expect(find.text('in 5 categories'), findsOneWidget);

    // Edit → PATCH
    await tester.ensureVisible(find.byTooltip('Edit or delete Papa'));
    await tester.tap(find.byTooltip('Edit or delete Papa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit category'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ElevatedButton, 'Save changes'), findsOneWidget);
    expect(find.text('Old papers'), findsOneWidget); // prefilled
    await tester.enterText(find.byType(TextField).first, 'Papa docs');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save changes'));
    await tester.pumpAndSettle();
    expect(server.calls, contains('PATCH /api/v1/user-categories/1'));
    expect(find.text('Papa docs'), findsOneWidget);

    // Delete → confirm → DELETE
    await tester.ensureVisible(find.byTooltip('Edit or delete Papa docs'));
    await tester.tap(find.byTooltip('Edit or delete Papa docs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete category'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Papa docs?'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(server.calls, contains('DELETE /api/v1/user-categories/1'));
    expect(find.text('Papa docs'), findsNothing);
    expect(find.text('in 4 categories'), findsOneWidget);
  });
}
