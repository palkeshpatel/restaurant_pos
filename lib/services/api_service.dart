import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../models/login_response.dart';
import '../models/pin_verification_response.dart';
import '../models/floor_response.dart';
import '../models/reserve_table_response.dart';
import '../models/menu_response.dart';
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

  static Future<ApiResponse<void>> logoutEmployee() async {
    try {
      final token = await getToken();
      if (token == null) {
        return ApiResponse<void>(
          success: false,
          message: 'No token found',
          data: null,
        );
      }

      final url = Uri.parse('${await baseUrl}/api/pos/logout');
      final response = await http.post(
        url,
        headers: _headers,
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        await setToken(null);
        return ApiResponse<void>(
          success: true,
          message: jsonResponse['message'] ?? 'Logout successful',
          data: null,
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: jsonResponse['message'] ?? 'Logout failed',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Error: ${e.toString()}',
        data: null,
      );
    }
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

  static Future<ApiResponse<FloorResponse>> getTables() async {
    try {
      final token = await getToken();
      if (token == null) {
        return ApiResponse<FloorResponse>(
          success: false,
          message: 'No token found',
          data: null,
        );
      }

      final url = Uri.parse('${await baseUrl}/api/pos/get-tables');
      final response = await http.get(
        url,
        headers: _headers,
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        final floorResponse = FloorResponse.fromJson(jsonResponse['data'] ?? []);
        return ApiResponse<FloorResponse>(
          success: true,
          message: jsonResponse['message'] ?? 'Tables retrieved successfully',
          data: floorResponse,
        );
      } else {
        return ApiResponse<FloorResponse>(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to fetch tables',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<FloorResponse>(
        success: false,
        message: 'Error: ${e.toString()}',
        data: null,
      );
    }
  }

  static Future<ApiResponse<ReserveTableResponse>> reserveTable({
    required int tableId,
    required String gratuityType,
    double? gratuityValue,
    int? guestCount,
    String? orderNotes,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return ApiResponse<ReserveTableResponse>(
          success: false,
          message: 'No token found',
          data: null,
        );
      }

      final url = Uri.parse('${await baseUrl}/api/pos/reserve_table');
      final body = {
        'table_id': tableId,
        'gratuity_type': gratuityType,
        'gratuity_value': gratuityValue ?? 0,
        'order_notes': orderNotes ?? '',
        if (guestCount != null) 'guest_count': guestCount,
      };

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        final data = jsonResponse['data'] ?? {};
        print('========================================');
        print('RESERVE_TABLE API RESPONSE:');
        print('Raw data: $data');
        print('order_ticket_id from API: ${data['order_ticket_id']}');
        print('order_ticket_title from API: ${data['order_ticket_title']}');
        print('========================================');
        
        final reserveResponse = ReserveTableResponse.fromJson(data);
        
        print('========================================');
        print('PARSED ReserveTableResponse:');
        print('reserveResponse.orderTicketId: ${reserveResponse.orderTicketId}');
        print('reserveResponse.orderTicketTitle: ${reserveResponse.orderTicketTitle}');
        print('reserveResponse.orderId: ${reserveResponse.orderId}');
        print('========================================');
        
        return ApiResponse<ReserveTableResponse>(
          success: true,
          message: jsonResponse['message'] ?? reserveResponse.message ?? 'Table reserved successfully',
          data: reserveResponse,
        );
      } else {
        return ApiResponse<ReserveTableResponse>(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to reserve table',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<ReserveTableResponse>(
        success: false,
        message: 'Error: ${e.toString()}',
        data: null,
      );
    }
  }

  static Future<ApiResponse<MenuResponse>> getMenu() async {
    try {
      final token = await getToken();
      if (token == null) {
        return ApiResponse<MenuResponse>(
          success: false,
          message: 'No token found',
          data: null,
        );
      }

      final url = Uri.parse('${await baseUrl}/api/pos/menu');
      final response = await http.get(
        url,
        headers: _headers,
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        final menuResponse = MenuResponse.fromJson(jsonResponse['data'] ?? []);
        return ApiResponse<MenuResponse>(
          success: true,
          message: jsonResponse['message'] ?? 'Menu retrieved successfully',
          data: menuResponse,
        );
      } else {
        return ApiResponse<MenuResponse>(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to fetch menu',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<MenuResponse>(
        success: false,
        message: 'Error: ${e.toString()}',
        data: null,
      );
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> sendOrder({
    required String orderTicketId,
    required int orderId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'No token found',
          data: null,
        );
      }

      final url = Uri.parse('${await baseUrl}/api/pos/order/send');
      final body = {
        'order_ticket_id': orderTicketId,
        'order_id': orderId,
        'items': items,
      };

      // Log the request body for debugging - FORMATTED JSON
      final requestBodyJson = jsonEncode(body);
      final formattedRequestBody = const JsonEncoder.withIndent('  ').convert(body);
      
      print('========================================');
      print('🚀 POST REQUEST: /api/pos/order/send');
      print('========================================');
      print('📍 URL: $url');
      print('🔑 Headers:');
      _headers.forEach((key, value) {
        if (key == 'Authorization') {
          print('   $key: Bearer ${value.toString().substring(7)}...');
        } else {
          print('   $key: $value');
        }
      });
      print('');
      print('📦 REQUEST BODY (Formatted JSON):');
      print(formattedRequestBody);
      print('');
      print('📦 REQUEST BODY (Raw JSON - for copy/paste):');
      print(requestBodyJson);
      print('========================================');
      print('');

      final response = await http.post(
        url,
        headers: _headers,
        body: requestBodyJson,
      );

      // Log the response
      print('========================================');
      print('📥 RESPONSE RECEIVED');
      print('========================================');
      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response Body:');
      try {
        final responseJson = jsonDecode(response.body);
        print(const JsonEncoder.withIndent('  ').convert(responseJson));
      } catch (e) {
        print(response.body);
      }
      print('========================================');
      print('');

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: jsonResponse['message'] ?? 'Order sent to kitchen successfully',
          data: jsonResponse['data'] as Map<String, dynamic>?,
        );
      } else {
        String errorMessage = jsonResponse['message'] ?? 'Failed to send order to kitchen';
        
        // Extract validation errors if present
        if (jsonResponse['errors'] != null) {
          final errors = jsonResponse['errors'] as Map<String, dynamic>;
          final errorList = errors.values
              .expand((e) => (e as List).map((msg) => msg.toString()))
              .join(', ');
          if (errorList.isNotEmpty) {
            errorMessage = errorList;
          }
        }

        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: errorMessage,
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error: ${e.toString()}',
        data: null,
      );
    }
  }

  static Future<ApiResponse<ReserveTableResponse>> resumeOrder({
    required String orderTicketId,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return ApiResponse<ReserveTableResponse>(
          success: false,
          message: 'No token found',
          data: null,
        );
      }

      final url = Uri.parse('${await baseUrl}/api/pos/resume_order');
      final body = {
        'order_ticket_id': orderTicketId,
      };

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        final data = jsonResponse['data'] ?? {};
        final resumeResponse = ReserveTableResponse.fromJson(data);
        
        return ApiResponse<ReserveTableResponse>(
          success: true,
          message: jsonResponse['message'] ?? 'Order resumed successfully',
          data: resumeResponse,
        );
      } else {
        return ApiResponse<ReserveTableResponse>(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to resume order',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<ReserveTableResponse>(
        success: false,
        message: 'Error: ${e.toString()}',
        data: null,
      );
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> fireItem({
    required String orderTicketId,
    List<int>? orderItemIds,
    List<Map<String, dynamic>>? itemsSequence,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'No token found',
          data: null,
        );
      }

      final url = Uri.parse('${await baseUrl}/api/pos/fire_item');
      final body = <String, dynamic>{
        'order_ticket_id': orderTicketId,
      };

      // Add optional order_item_ids if provided
      if (orderItemIds != null && orderItemIds.isNotEmpty) {
        body['order_item_ids'] = orderItemIds;
      }

      // Add optional items_sequence if provided
      if (itemsSequence != null && itemsSequence.isNotEmpty) {
        body['items_sequence'] = itemsSequence;
      }

      print('========================================');
      print('🔥 FIRING ITEMS - API Request');
      print('========================================');
      print('URL: $url');
      print('Body: ${jsonEncode(body)}');
      print('========================================');

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      final jsonResponse = jsonDecode(response.body);

      print('========================================');
      print('🔥 FIRING ITEMS - API Response');
      print('========================================');
      print('Status Code: ${response.statusCode}');
      print('Response: ${const JsonEncoder.withIndent('  ').convert(jsonResponse)}');
      print('========================================');

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: jsonResponse['message'] ?? 'Items fired successfully',
          data: jsonResponse['data'] as Map<String, dynamic>?,
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to fire items',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error: ${e.toString()}',
        data: null,
      );
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> updateItemSequence({
    required String orderTicketId,
    required int orderItemId,
    required int sequence,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'No token found',
          data: null,
        );
      }

      final url = Uri.parse('${await baseUrl}/api/pos/order-item/update-sequence');
      final body = {
        'order_ticket_id': orderTicketId,
        'order_item_id': orderItemId,
        'sequence': sequence,
      };

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: jsonResponse['message'] ?? 'Sequence updated successfully',
          data: jsonResponse['data'] as Map<String, dynamic>?,
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to update sequence',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error: ${e.toString()}',
        data: null,
      );
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> processPayment({
    required String orderTicketId,
    required String type, // 'cash' or 'online'
    required double amount,
    double tipAmount = 0.0,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'No token found',
          data: null,
        );
      }

      final url = Uri.parse('${await baseUrl}/api/pos/order/payment');
      final body = {
        'order_ticket_id': orderTicketId,
        'type': type,
        'amount': amount,
        'tip_amount': tipAmount,
      };

      print('========================================');
      print('💳 PROCESSING PAYMENT - API Request');
      print('========================================');
      print('URL: $url');
      print('Body: ${jsonEncode(body)}');
      print('========================================');

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      final jsonResponse = jsonDecode(response.body);

      print('========================================');
      print('💳 PROCESSING PAYMENT - API Response');
      print('========================================');
      print('Status Code: ${response.statusCode}');
      print('Response: ${const JsonEncoder.withIndent('  ').convert(jsonResponse)}');
      print('========================================');

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: jsonResponse['message'] ?? 'Payment processed successfully',
          data: jsonResponse['data'] as Map<String, dynamic>?,
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: jsonResponse['message'] ?? 'Payment processing failed',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error: ${e.toString()}',
        data: null,
      );
    }
  }
}
