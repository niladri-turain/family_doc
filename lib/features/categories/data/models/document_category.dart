/// A document category: a global one (GET /api/v1/categories) or one the
/// user made (GET /api/v1/user-categories, [isCustom] = true).
class DocumentCategory {
  const DocumentCategory({
    required this.id,
    required this.name,
    this.description = '',
    this.documentCount = 0,
    this.isCustom = false,
  });

  final int id;
  final String name;

  /// Comma separated examples, e.g. "Aadhaar,Pan,Voter".
  final String description;

  /// Documents are not built yet, so this is 0 unless the API sends it.
  final int documentCount;

  /// Made by the user (ids can overlap with global categories).
  final bool isCustom;

  /// "Aadhaar,Pan,Voter" → ["Aadhaar", "Pan", "Voter"]
  List<String> get examples => description
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  factory DocumentCategory.fromJson(
    Map<String, dynamic> json, {
    bool isCustom = false,
  }) => DocumentCategory(
    id: (json['id'] as num).toInt(),
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    documentCount: (json['documentCount'] as num?)?.toInt() ?? 0,
    isCustom: isCustom,
  );
}
