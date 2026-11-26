import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/family_service.dart';
import '../../data/models/family_member.dart';
import '../../data/models/relation.dart';

/// Family members state. Screens read it with `context.watch<FamilyProvider>()`.
class FamilyProvider extends ChangeNotifier {
  FamilyProvider({required FamilyService service}) : _service = service;

  final FamilyService _service;

  List<FamilyMember> _members = [];
  List<FamilyMember> get members => _members;

  bool _hasLoaded = false;

  /// True after the first successful fetch.
  bool get hasLoaded => _hasLoaded;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  /// Error from the last fetch (shown with a Retry button).
  ApiException? _error;
  ApiException? get error => _error;

  String _query = '';
  String get query => _query;

  /// "Add family member" is only allowed after "Self" is added.
  bool get hasSelf => _members.any((m) => m.isSelf);

  int get totalDocuments => _members.fold(0, (sum, m) => sum + m.documentCount);

  /// Self first, then in the order the server returns them.
  List<FamilyMember> get filteredMembers {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _members;
    return _members
        .where(
          (m) =>
              m.fullName.toLowerCase().contains(q) ||
              m.relation.label.toLowerCase().contains(q),
        )
        .toList();
  }

  /// GET the member list (called when My Family opens and on pull-to-refresh).
  Future<void> fetchMembers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _members = _selfFirst(await _service.getMembers());
      _hasLoaded = true;
    } on ApiException catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _query = query;
    notifyListeners();
  }

  /// POST a new member. Throws [ApiException] with the server message.
  Future<FamilyMember> addMember({
    required Relation relation,
    required String fullName,
    required DateTime dateOfBirth,
    required Gender gender,
    String? mobile,
    File? photo,
  }) async {
    _isSaving = true;
    notifyListeners();
    try {
      final member = await _service.addMember(
        relation: relation,
        fullName: fullName.trim(),
        dateOfBirth: dateOfBirth,
        gender: gender,
        mobile: mobile,
        photo: photo,
      );
      _members = _selfFirst([..._members, member]);
      return member;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// PATCH an existing member. Throws [ApiException] with the server message.
  Future<FamilyMember> updateMember(
    FamilyMember member, {
    required Relation relation,
    required String fullName,
    required DateTime dateOfBirth,
    required Gender gender,
    String? mobile,
    File? photo,
    bool removePhoto = false,
  }) async {
    _isSaving = true;
    notifyListeners();
    try {
      final updated = await _service.updateMember(
        member.id,
        relation: relation,
        fullName: fullName.trim(),
        dateOfBirth: dateOfBirth,
        gender: gender,
        mobile: mobile,
        photo: photo,
        removePhoto: removePhoto,
      );
      _members = _selfFirst([
        for (final m in _members) m.id == member.id ? updated : m,
      ]);
      return updated;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Id of the member being deleted (to show a spinner on that row).
  int? _deletingId;
  int? get deletingId => _deletingId;

  /// DELETE a member. Throws [ApiException] with the server message.
  Future<void> deleteMember(FamilyMember member) async {
    _deletingId = member.id;
    notifyListeners();
    try {
      await _service.deleteMember(member.id);
      _members = _members.where((m) => m.id != member.id).toList();
    } on ApiException catch (e) {
      // Already gone on the server: drop it here too.
      if (e.statusCode == 404) {
        _members = _members.where((m) => m.id != member.id).toList();
      } else {
        rethrow;
      }
    } finally {
      _deletingId = null;
      notifyListeners();
    }
  }

  /// The "Self" member (used for the profile photo and name), if added.
  FamilyMember? get self {
    for (final m in _members) {
      if (m.isSelf) return m;
    }
    return null;
  }

  void clear() {
    _members = [];
    _hasLoaded = false;
    _query = '';
    notifyListeners();
  }

  static List<FamilyMember> _selfFirst(List<FamilyMember> list) => [
    ...list.where((m) => m.isSelf),
    ...list.where((m) => !m.isSelf),
  ];
}
