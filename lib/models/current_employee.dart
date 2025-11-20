import 'employee.dart';

class CurrentEmployee {
  final Employee employee;
  final String token;
  final DateTime loginTime;
  final String roleName;

  CurrentEmployee({
    required this.employee,
    required this.token,
    required this.loginTime,
    required this.roleName,
  });

  Map<String, dynamic> toJson() {
    return {
      'employee': {
        'id': employee.id,
        'first_name': employee.firstName,
        'last_name': employee.lastName,
        'email': employee.email,
        'avatar': employee.avatar,
        'is_active': employee.isActive,
      },
      'token': token,
      'login_time': loginTime.toIso8601String(),
      'role_name': roleName,
    };
  }

  factory CurrentEmployee.fromJson(Map<String, dynamic> json) {
    final employeeData = json['employee'] ?? json;
    return CurrentEmployee(
      employee: Employee.fromJson(employeeData),
      token: json['token'] ?? '',
      loginTime: DateTime.parse(json['login_time'] ?? DateTime.now().toIso8601String()),
      roleName: json['role_name'] ?? '',
    );
  }
}

