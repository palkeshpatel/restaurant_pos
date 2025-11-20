import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../models/login_response.dart';
import '../models/pin_verification_response.dart';
import 'storage_service.dart';

class ApiService {
  static String? _baseUrl;
  static String? _token;

  static Future<String> get baseUrl async {
    _baseUrl ??= await StorageService.getBaseUrl();
    return _baseUrl ?? 'http://localhost:8000';
  }

  static Future<void> setToken(String? token) async {
    _token = token;
    if (token != null) {
      await StorageService.saveToken(token);
    } else {
      await StorageService.removeToken();
    }
  }

  static Future<String?> getToken() async {
    _token ??= await StorageService.getToken();
    return _token;
  }

  static Future<void> initialize() async {
    _baseUrl = await StorageService.getBaseUrl();
    _token = await StorageService.getToken();
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static Future<ApiResponse<LoginResponse>> login(String email, String password) async {
    try {
      final url = Uri.parse('${await baseUrl}/api/auth/login');
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        final loginResponse = LoginResponse.fromJson(jsonResponse['data']);
        await setToken(loginResponse.token);
        return ApiResponse<LoginResponse>(
          success: true,
          message: jsonResponse['message'] ?? 'Login successful',
          data: loginResponse,
        );
      } else {
        return ApiResponse<LoginResponse>(
          success: false,
          message: jsonResponse['message'] ?? 'Login failed',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<LoginResponse>(
        success: false,
        message: 'Error: ${e.toString()}',
        data: null,
      );
    }
  }

  static Future<ApiResponse<LoginResponse>> me() async {
    try {
      final token = await getToken();
      if (token == null) {
        return ApiResponse<LoginResponse>(
          success: false,
          message: 'No token found',
          data: null,
        );
      }

      final url = Uri.parse('${await baseUrl}/api/auth/me');
      final response = await http.get(
        url,
        headers: _headers,
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        final loginResponse = LoginResponse.fromJson(jsonResponse['data']);
        await setToken(loginResponse.token);
        return ApiResponse<LoginResponse>(
          success: true,
          message: jsonResponse['message'] ?? 'Success',
          data: loginResponse,
        );
      } else {
        return ApiResponse<LoginResponse>(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to fetch user data',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<LoginResponse>(
        success: false,
        message: 'Error: ${e.toString()}',
        data: null,
      );
    }
  }

  static Future<void> logout() async {
    await setToken(null);
  }

  static Future<ApiResponse<PinVerificationResponse>> verifyPin(int employeeId, String pin4) async {
    try {
      final url = Uri.parse('${await baseUrl}/api/pos/verify-pin');
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'employee_id': employeeId,
          'pin4': pin4,
        }),
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        final pinVerificationResponse = PinVerificationResponse.fromJson(jsonResponse['data']);
        await setToken(pinVerificationResponse.token);
        return ApiResponse<PinVerificationResponse>(
          success: true,
          message: jsonResponse['message'] ?? 'PIN verified successfully',
          data: pinVerificationResponse,
        );
      } else {
        return ApiResponse<PinVerificationResponse>(
          success: false,
          message: jsonResponse['message'] ?? 'PIN verification failed',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<PinVerificationResponse>(
        success: false,
        message: 'Error: ${e.toString()}',
        data: null,
      );
    }
  }
}
