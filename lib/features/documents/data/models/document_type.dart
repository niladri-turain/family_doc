/// A kind of document inside a category, e.g. "Graduation Marksheet"
/// under Education. From GET /api/v1/document-types?categoryId={id}.
class DocumentType {
  const DocumentType({
    required this.id,
    required this.name,
    required this.categoryId,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final int id;
  final String name;
  final int categoryId;
  final int sortOrder;
  final bool isActive;

  factory DocumentType.fromJson(Map<String, dynamic> json) => DocumentType(
    id: json['id'] as int,
    name: (json['name'] as String? ?? '').trim(),
    categoryId: json['categoryId'] as int? ?? 0,
    sortOrder: json['sortOrder'] as int? ?? 0,
    isActive: json['isActive'] as bool? ?? true,
  );
}
