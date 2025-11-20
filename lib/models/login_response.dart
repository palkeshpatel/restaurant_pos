import 'user.dart';
import 'business.dart';
import 'role.dart';

class LoginResponse {
  final String token;
  final String tokenType;
  final User user;
  final Business business;
  final List<Role> roles;

  LoginResponse({
    required this.token,
    required this.tokenType,
    required this.user,
    required this.business,
    required this.roles,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] ?? '',
      tokenType: json['token_type'] ?? 'Bearer',
      user: User.fromJson(json['user'] ?? {}),
      business: Business.fromJson(json['business'] ?? {}),
      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((role) => Role.fromJson(role))
          .toList(),
    );
  }
}
