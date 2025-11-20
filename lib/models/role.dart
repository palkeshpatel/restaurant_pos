import 'employee.dart';

class Role {
  final int id;
  final String name;
  final List<Employee> employees;

  Role({
    required this.id,
    required this.name,
    required this.employees,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      employees: (json['employees'] as List<dynamic>? ?? [])
          .map((emp) => Employee.fromJson(emp))
          .toList(),
    );
  }
}
