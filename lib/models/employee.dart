class Employee {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? avatar;
  final bool isActive;

  Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatar,
    required this.isActive,
  });

  String get fullName => '$firstName $lastName';
  
  String get initials {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    } else if (firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    }
    return 'E';
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      isActive: json['is_active'] ?? false,
    );
  }
}
