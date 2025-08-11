import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Headers for API requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Headers with authentication token
  Map<String, String> getAuthHeaders(String token) => {
    ..._headers,
    'Authorization': 'Bearer $token',
  };

  // Generic GET request
  Future<Map<String, dynamic>> get(String endpoint, {String? token}) async {
    try {
      print('Making GET request to: ${ApiConfig.getUrl(endpoint)}');
      
      final response = await http.get(
        Uri.parse(ApiConfig.getUrl(endpoint)),
        headers: token != null ? getAuthHeaders(token) : _headers,
      ).timeout(Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return _handleResponse(response);
    } catch (e) {
      print('API Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }

  // Generic POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
  }) async {
    try {
      print('Making POST request to: ${ApiConfig.getUrl(endpoint)}');
      print('Data: $data');
      
      // Convert data to form format
      Map<String, String> formData = {};
      if (data != null) {
        data.forEach((key, value) {
          formData[key] = value.toString();
        });
      }
      
      print('Form data: $formData');
      print('Body: ${formData.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}');
      
      final response = await http.post(
        Uri.parse(ApiConfig.getUrl(endpoint)),
        headers: token != null ? {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        } : {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: formData.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&'),
      ).timeout(Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return _handleResponse(response);
    } catch (e) {
      print('API Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }

  // Handle API response
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      print('Handling response with status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      final body = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Check if the response has the expected format
        if (body is Map<String, dynamic>) {
          return {
            'success': body['success'] ?? true,
            'message': body['message'] ?? 'Success',
            'data': body['data'] ?? body,
          };
        } else {
          return {
            'success': true,
            'message': 'Success',
            'data': body,
          };
        }
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Request failed with status ${response.statusCode}',
          'data': null,
        };
      }
    } catch (e) {
      print('Error parsing response: $e');
      return {
        'success': false,
        'message': 'Invalid response format: ${e.toString()}',
        'data': null,
      };
    }
  }

  // Auth methods
  Future<Map<String, dynamic>> register({
    required String phone,
    required String pin,
    required String name,
  }) async {
    return post(ApiConfig.register, data: {
      'phone': phone,
      'pin': pin,
      'name': name,
    });
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String pin,
  }) async {
    return post(ApiConfig.login, data: {
      'phone': phone,
      'pin': pin,
    });
  }

  // Auction methods
  Future<Map<String, dynamic>> getUpcomingAuctions() async {
    return get(ApiConfig.upcomingAuctions);
  }

  Future<Map<String, dynamic>> getLiveAuctions() async {
    return get(ApiConfig.liveAuctions);
  }

  Future<Map<String, dynamic>> getCompletedAuctions() async {
    return get(ApiConfig.completedAuctions);
  }

  Future<Map<String, dynamic>> getAuctionDetail(int auctionId) async {
    return get(ApiConfig.auctionDetail + '/$auctionId');
  }

  Future<Map<String, dynamic>> placeBid({
    required int auctionId,
    required double amount,
    required String token,
  }) async {
    return post(
      ApiConfig.placeBid + '/$auctionId/bid',
      data: {'amount': amount},
      token: token,
    );
  }

  // Wallet methods
  Future<Map<String, dynamic>> getWallet(String token) async {
    return get(ApiConfig.wallet, token: token);
  }

  Future<Map<String, dynamic>> topUp({
    required double amount,
    String? note,
    required String token,
  }) async {
    return post(
      ApiConfig.topUp,
      data: {
        'amount': amount,
        if (note != null) 'note': note,
      },
      token: token,
    );
  }

  Future<Map<String, dynamic>> getTransactions(String token) async {
    return get(ApiConfig.transactions, token: token);
  }

  // Payment methods
  Future<Map<String, dynamic>> initializeTopUp({
    required int userId,
    required double amount,
    required String phone,
  }) async {
    return post(
      ApiConfig.initializeTopUp,
      data: {
        'user_id': userId,
        'amount': amount,
        'phone': phone,
      },
    );
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String transactionId,
  }) async {
    return get(ApiConfig.verifyPayment + '/$transactionId');
  }

  Future<Map<String, dynamic>> getPaymentHistory(String token) async {
    return get(ApiConfig.paymentHistory, token: token);
  }

  Future<Map<String, dynamic>> getWalletStats() async {
    return get(ApiConfig.walletStats);
  }

  // User methods
  Future<Map<String, dynamic>> getUserProfile(String token) async {
    return get(ApiConfig.userProfile, token: token);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String token,
  }) async {
    return post(
      ApiConfig.updateProfile,
      data: {'name': name},
      token: token,
    );
  }

  Future<Map<String, dynamic>> getBidHistory(String token) async {
    return get(ApiConfig.bidHistory, token: token);
  }

  // Rules method
  Future<Map<String, dynamic>> getRules() async {
    return get(ApiConfig.rules);
  }
} 