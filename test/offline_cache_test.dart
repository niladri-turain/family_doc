import 'dart:convert';
import 'dart:io';

import 'package:family_doc/core/network/api_client.dart';
import 'package:family_doc/core/network/api_exception.dart';
import 'package:family_doc/core/network/connection_status.dart';
import 'package:family_doc/core/storage/api_cache.dart';
import 'package:family_doc/core/storage/token_storage.dart';
import 'package:family_doc/features/auth/data/auth_service.dart';
import 'package:family_doc/features/categories/data/category_service.dart';
import 'package:family_doc/features/documents/data/document_service.dart';
import 'package:family_doc/features/family/data/family_service.dart';
import 'package:family_doc/features/family/data/models/relation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A server that can drop off the network, with members and categories.
class Server {
  bool offline = false;
  int status = 200;
  final members = <Map<String, dynamic>>[
    {'id': 1, 'relation': 'self', 'fullName': 'Rahul Sharma'},
  ];
  final userCategories = <Map<String, dynamic>>[];
  var _id = 10;

  late final client = MockClient((req) async {
    if (offline) throw const SocketException('offline');
    if (status != 200) return http.Response('{}', status);
    final path = req.url.path;
    final body = req.body.isEmpty ? null : jsonDecode(req.body);
    http.Response ok(Object o, [int code = 200]) =>
        http.Response(jsonEncode(o), code);
    if (path == '/api/v1/users/me') {
      return ok({
        'user': {'id': 1, 'mobile': '+917059238072'},
      });
    }
    if (path == '/api/v1/family-members') {
      if (req.method == 'GET') return ok({'members': members});
      final m = {'id': ++_id, ...body as Map<String, dynamic>};
      members.add(m);
      return ok({'member': m}, 201);
    }
    if (path.startsWith('/api/v1/family-members/')) {
      final id = int.parse(path.split('/').last);
      if (req.method == 'DELETE') {
        members.removeWhere((m) => m['id'] == id);
        return http.Response('', 204);
      }
      final i = members.indexWhere((m) => m['id'] == id);
      members[i] = {...members[i], ...body as Map<String, dynamic>};
      return ok({'member': members[i]});
    }
    if (path == '/api/v1/categories') {
      return ok({
        'categories': [
          {'id': 1, 'name': 'Education'},
        ],
      });
    }
    if (path == '/api/v1/user-categories') {
      if (req.method == 'GET') return ok({'categories': userCategories});
      final c = {'id': ++_id, ...body as Map<String, dynamic>};
      userCategories.add(c);
      return ok({'category': c}, 201);
    }
    if (path.startsWith('/api/v1/user-categories/')) {
      final id = int.parse(path.split('/').last);
      userCategories.removeWhere((c) => c['id'] == id);
      return http.Response('', 204);
    }
    if (path == '/api/v1/document-types') {
      return ok({
        'documentTypes': [
          {'id': 11, 'name': 'Graduation Marksheet', 'categoryId': 1},
        ],
      });
    }
    return http.Response('', 404);
  });
}

void main() {
  late Server server;
  late MemoryApiCache cache;
  late ConnectionStatus status;
  late ApiClient api;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    server = Server();
    cache = MemoryApiCache();
    status = ConnectionStatus();
    api = ApiClient(
      tokenStorage: TokenStorage(),
      client: server.client,
      status: status,
    );
  });

  test('members: saved online, shown offline, kept in step', () async {
    final family = FamilyService(api, cache);

    // Nothing saved yet + offline → the network error as before
    server.offline = true;
    await expectLater(
      family.getMembers(),
      throwsA(isA<ApiException>().having((e) => e.isNetworkError, 'net', true)),
    );
    expect(status.isOffline, isTrue);

    server.offline = false;
    expect((await family.getMembers()).single.fullName, 'Rahul Sharma');
    expect(status.isOffline, isFalse);

    // Add, edit, delete online: the saved list follows without a refetch
    final sunil = await family.addMember(
      relation: Relation.father,
      fullName: 'Sunil Sharma',
      dateOfBirth: DateTime(1966),
      gender: Gender.male,
    );
    final rina = await family.addMember(
      relation: Relation.mother,
      fullName: 'Rina Sharma',
      dateOfBirth: DateTime(1970),
      gender: Gender.female,
    );
    await family.updateMember(
      sunil.id,
      relation: Relation.father,
      fullName: 'Sunil K Sharma',
      dateOfBirth: DateTime(1966),
      gender: Gender.male,
    );
    await family.deleteMember(rina.id);

    server.offline = true;
    final saved = await family.getMembers();
    expect(saved.map((m) => m.fullName), ['Rahul Sharma', 'Sunil K Sharma']);
    expect(status.isOffline, isTrue);

    // Offline writes fail with a clear message, the saved list is untouched
    await expectLater(
      family.deleteMember(sunil.id),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains("You're offline"),
        ),
      ),
    );
    expect((await family.getMembers()).length, 2);
  });

  test('server errors are not hidden by saved data', () async {
    final family = FamilyService(api, cache);
    await family.getMembers();
    server.status = 401;
    await expectLater(
      family.getMembers(),
      throwsA(isA<ApiException>().having((e) => e.isUnauthorized, '401', true)),
    );
  });

  test('categories, document types and profile work offline', () async {
    final categories = CategoryService(api, cache);
    final types = DocumentService(api, cache);
    final auth = AuthService(api, cache);
    await categories.getCategories();
    final bikes = await categories.addCategory(name: 'Bikes');
    final old = await categories.addCategory(name: 'Old');
    await categories.deleteCategory(old.id);
    await types.getDocumentTypes(1);
    await auth.getMe();

    server.offline = true;
    final list = await categories.getCategories();
    expect(list.map((c) => c.name), ['Education', 'Bikes']);
    expect(list.last.id, bikes.id);
    expect(list.last.isCustom, isTrue);
    expect(
      (await types.getDocumentTypes(1)).single.name,
      'Graduation Marksheet',
    );
    // Never saved for this category → still the network error
    await expectLater(types.getDocumentTypes(2), throwsA(isA<ApiException>()));
    expect((await auth.getMe()).mobile, '+917059238072');
  });

  test('logout data: clear empties everything', () async {
    await FamilyService(api, cache).getMembers();
    expect(cache.data, isNotEmpty);
    await cache.clear();
    expect(cache.data, isEmpty);
  });
}
