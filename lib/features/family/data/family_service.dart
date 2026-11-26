import 'dart:io';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'models/family_member.dart';
import 'models/relation.dart';

/// Family member API calls. The bearer token is added by [ApiClient].
class FamilyService {
  FamilyService(this._api);

  final ApiClient _api;

  /// GET /api/v1/family-members → {"total": 5, "members": [...]}
  Future<List<FamilyMember>> getMembers({String? search}) async {
    final data = await _api.get(
      ApiEndpoints.familyMembers,
      query: (search == null || search.isEmpty) ? null : {'search': search},
    );
    final list = (data is Map ? data['members'] : data) as List? ?? const [];
    return list
        .map((e) => FamilyMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/v1/family-members → {"member": {...}}
  /// JSON without a photo, multipart/form-data (`photo` field) with one.
  Future<FamilyMember> addMember({
    required Relation relation,
    required String fullName,
    required DateTime dateOfBirth,
    required Gender gender,
    String? mobile,
    File? photo,
  }) async {
    final fields = <String, String>{
      'relation': relation.name,
      'fullName': fullName,
      'dateOfBirth': formatDate(dateOfBirth),
      'gender': gender.name,
      if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
    };

    final data = photo == null
        ? await _api.post(ApiEndpoints.familyMembers, body: fields)
        : await _api.multipart(
            ApiEndpoints.familyMembers,
            fields: fields,
            files: {'photo': photo.path},
          );
    return FamilyMember.fromJson(
      (data as Map<String, dynamic>)['member'] as Map<String, dynamic>,
    );
  }

  /// PATCH /api/v1/family-members/{id} → {"member": {...}}
  /// JSON without a new photo (an empty mobile is sent as null to clear it,
  /// [removePhoto] sends photoUrl: null); multipart with a new `photo`.
  Future<FamilyMember> updateMember(
    int id, {
    required Relation relation,
    required String fullName,
    required DateTime dateOfBirth,
    required Gender gender,
    String? mobile,
    File? photo,
    bool removePhoto = false,
  }) async {
    final hasMobile = mobile != null && mobile.isNotEmpty;
    final endpoint = ApiEndpoints.familyMember(id);
    final data = photo == null
        ? await _api.patch(
            endpoint,
            body: {
              'relation': relation.name,
              'fullName': fullName,
              'dateOfBirth': formatDate(dateOfBirth),
              'gender': gender.name,
              'mobile': hasMobile ? mobile : null,
              if (removePhoto) 'photoUrl': null,
            },
          )
        : await _api.multipart(
            endpoint,
            method: 'PATCH',
            fields: {
              'relation': relation.name,
              'fullName': fullName,
              'dateOfBirth': formatDate(dateOfBirth),
              'gender': gender.name,
              'mobile': hasMobile ? mobile : '',
            },
            files: {'photo': photo.path},
          );
    return FamilyMember.fromJson(
      (data as Map<String, dynamic>)['member'] as Map<String, dynamic>,
    );
  }

  /// DELETE /api/v1/family-members/{id} → 204
  Future<void> deleteMember(int id) =>
      _api.delete(ApiEndpoints.familyMember(id));

  /// 2026-01-05 → "2026-01-05" (the API's date format).
  static String formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
