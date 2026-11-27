/// A kind of document inside a category, e.g. "Graduation Marksheet"
/// under Education. From GET /api/v1/document-types?categoryId={id}, or
/// one the user added ([isCustom], saved on the phone, negative [id]).
class DocumentType {
  const DocumentType({
    required this.id,
    required this.name,
    required this.categoryId,
    this.sortOrder = 0,
    this.isActive = true,
    this.isCustom = false,
    this.customCategory = false,
  });

  final int id;
  final String name;
  final int categoryId;
  final int sortOrder;
  final bool isActive;

  /// Added by the user on this phone.
  final bool isCustom;

  /// [categoryId] is one of the user's own categories.
  final bool customCategory;

  factory DocumentType.fromJson(Map<String, dynamic> json) => DocumentType(
    id: json['id'] as int,
    name: (json['name'] as String? ?? '').trim(),
    categoryId: json['categoryId'] as int? ?? 0,
    sortOrder: json['sortOrder'] as int? ?? 0,
    isActive: json['isActive'] as bool? ?? true,
  );

  factory DocumentType.fromMap(Map<dynamic, dynamic> map) => DocumentType(
    id: map['id'] as int,
    name: map['name'] as String,
    categoryId: map['categoryId'] as int,
    customCategory: map['customCategory'] as bool? ?? false,
    isCustom: true,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'categoryId': categoryId,
    'customCategory': customCategory,
  };
}
