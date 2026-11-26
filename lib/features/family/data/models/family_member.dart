import '../../../../core/network/api_endpoints.dart';
import 'relation.dart';

/// One family member as returned by /api/v1/family-members.
class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.fullName,
    required this.relation,
    this.dateOfBirth,
    this.gender,
    this.mobile,
    this.photoUrl,
    this.documentCount = 0,
    this.createdAt,
  });

  final int id;
  final String fullName;
  final Relation relation;
  final DateTime? dateOfBirth;
  final Gender? gender;

  /// As the server stores it, e.g. "+919876543210".
  final String? mobile;
  final String? photoUrl;

  /// Documents are not built yet, so this is 0 unless the API sends it.
  final int documentCount;
  final DateTime? createdAt;

  bool get isSelf => relation == Relation.self;

  String get initials => initialsOf(fullName);

  /// "Rahul Sharma" → "RS", "Aarav" → "A".
  static String initialsOf(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  /// "https://…" stays as is; "/uploads/a.jpg" gets the API base URL in front.
  static String? _absoluteUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '${ApiEndpoints.baseUrl}${url.startsWith('/') ? '' : '/'}$url';
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    id: (json['id'] as num).toInt(),
    fullName: json['fullName']?.toString() ?? '',
    relation: Relation.fromApi(json['relation']?.toString()),
    dateOfBirth: DateTime.tryParse(json['dateOfBirth']?.toString() ?? ''),
    gender: Gender.fromApi(json['gender']?.toString()),
    mobile: json['mobile']?.toString(),
    photoUrl: _absoluteUrl(json['photoUrl']?.toString()),
    documentCount: (json['documentCount'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
  );
}
