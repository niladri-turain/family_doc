/// A document category from GET /api/v1/categories.
class DocumentCategory {
  const DocumentCategory({
    required this.id,
    required this.name,
    this.description = '',
    this.documentCount = 0,
  });

  final int id;
  final String name;

  /// Comma separated examples, e.g. "Aadhaar,Pan,Voter".
  final String description;

  /// Documents are not built yet, so this is 0 unless the API sends it.
  final int documentCount;

  /// "Aadhaar,Pan,Voter" → ["Aadhaar", "Pan", "Voter"]
  List<String> get examples => description
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  factory DocumentCategory.fromJson(Map<String, dynamic> json) =>
      DocumentCategory(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        documentCount: (json['documentCount'] as num?)?.toInt() ?? 0,
      );
}
