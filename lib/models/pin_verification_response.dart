import 'employee.dart';

class PinVerificationResponse {
  final Employee employee;
  final bool verified;
  final String token;
  final String tokenType;

  PinVerificationResponse({
    required this.employee,
    required this.verified,
    required this.token,
    required this.tokenType,
  });

  factory PinVerificationResponse.fromJson(Map<String, dynamic> json) {
    return PinVerificationResponse(
      employee: Employee.fromJson(json['employee'] ?? {}),
      verified: json['verified'] ?? false,
      token: json['token'] ?? '',
      tokenType: json['token_type'] ?? 'Bearer',
    );
  }
}
