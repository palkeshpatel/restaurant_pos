class User {
  final int id;
  final int businessId;
  final String name;
  final String email;
  final String? emailVerifiedAt;
  final bool isSuperAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.businessId,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    required this.isSuperAdmin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      businessId: json['business_id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      emailVerifiedAt: json['email_verified_at'],
      isSuperAdmin: json['is_super_admin'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}