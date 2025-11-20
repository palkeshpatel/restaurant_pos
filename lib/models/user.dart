class User {
  final int id;
  final int businessId;
  final String name;
  final String email;
  final String? avatar;
  final String? emailVerifiedAt;
  final bool isSuperAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.businessId,
    required this.name,
    required this.email,
    this.avatar,
    this.emailVerifiedAt,
    required this.isSuperAdmin,
    required this.createdAt,
    required this.updatedAt,
  });

  String get initials {
    if (name.isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty) {
        return parts[0][0].toUpperCase();
      }
    }
    return 'U';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      businessId: json['business_id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      emailVerifiedAt: json['email_verified_at'],
      isSuperAdmin: json['is_super_admin'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}