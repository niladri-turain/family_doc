/// A document the user saved on this phone (file + details in a Hive box).
/// The file lives in the app's documents folder at [storedName]
/// (`<id>/<name>.<ext>`, so opening and sharing show the user's name);
/// only this relative path is kept because iOS can move the app folder.
class SavedDocument {
  const SavedDocument({
    required this.id,
    required this.memberId,
    required this.categoryId,
    required this.customCategory,
    required this.name,
    required this.fileName,
    required this.storedName,
    required this.size,
    required this.createdAt,
    this.typeId,
    this.typeName,
  });

  final String id;
  final int memberId;
  final int categoryId;

  /// True for the user's own categories (their ids can match built-in ones).
  final bool customCategory;
  final int? typeId;
  final String? typeName;
  final String name;

  /// Original file name, e.g. bsc_marksheet_2018.pdf.
  final String fileName;
  final String storedName;
  final int size;
  final DateTime createdAt;

  /// The file name the user sees when sharing: `<name>.<ext>`.
  String get displayFileName => fileNameFor(name, extension);

  /// Makes [name] safe as a file name and adds the extension.
  static String fileNameFor(String name, String extension) {
    var safe = name
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    while (safe.startsWith('.')) {
      safe = safe.substring(1);
    }
    if (safe.length > 80) safe = safe.substring(0, 80).trim();
    if (safe.isEmpty) safe = 'document';
    return extension.isEmpty ? safe : '$safe.$extension';
  }

  SavedDocument copyWith({String? name, String? storedName}) => SavedDocument(
    id: id,
    memberId: memberId,
    categoryId: categoryId,
    customCategory: customCategory,
    typeId: typeId,
    typeName: typeName,
    name: name ?? this.name,
    fileName: fileName,
    storedName: storedName ?? this.storedName,
    size: size,
    createdAt: createdAt,
  );

  /// Lower-case extension without the dot ("pdf", "jpg"…), or "".
  String get extension {
    final dot = fileName.lastIndexOf('.');
    return dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
  }

  bool get isImage =>
      const {'jpg', 'jpeg', 'png', 'heic', 'heif', 'webp'}.contains(extension);

  factory SavedDocument.fromMap(Map<dynamic, dynamic> map) => SavedDocument(
    id: map['id'] as String,
    memberId: map['memberId'] as int,
    categoryId: map['categoryId'] as int,
    customCategory: map['customCategory'] as bool? ?? false,
    typeId: map['typeId'] as int?,
    typeName: map['typeName'] as String?,
    name: map['name'] as String,
    fileName: map['fileName'] as String,
    storedName: map['storedName'] as String,
    size: map['size'] as int? ?? 0,
    createdAt:
        DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'memberId': memberId,
    'categoryId': categoryId,
    'customCategory': customCategory,
    'typeId': typeId,
    'typeName': typeName,
    'name': name,
    'fileName': fileName,
    'storedName': storedName,
    'size': size,
    'createdAt': createdAt.toIso8601String(),
  };
}
