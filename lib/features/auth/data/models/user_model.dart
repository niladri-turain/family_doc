class UserModel {
  const UserModel({
    required this.id,
    required this.mobile,
    this.createdAt,
  });

  final int id;
  final String mobile;
  final DateTime? createdAt;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['id'] as num).toInt(),
        mobile: json['mobile']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}
