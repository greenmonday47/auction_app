import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import '../utils/api_service.dart';
import '../models/payment.dart';
import '../models/api_response.dart';

class PaymentService {
  static const String _gmpayDepositUrl = 'https://debit.gmpayapp.site/public/deposit/custom';
  static const String _gmpayStatusUrl = 'https://debit.gmpayapp.site/public/transaction-status';

  /// Initialize a wallet top-up payment
  static Future<ApiResponse<Payment>> initializeTopUp({
    required int userId,
    required double amount,
    required String phoneNumber,
  }) async {
    try {
      final response = await ApiService().post(
        ApiConfig.initializeTopUp,
        data: {
          'user_id': userId,
          'amount': amount.toString(),
          'phone': phoneNumber,
        },
      );

      if (response['success'] == true) {
        return ApiResponse<Payment>(
          success: true,
          data: Payment.fromJson(response['data']),
          message: response['message'] ?? 'Top-up initialized successfully',
        );
      } else {
        return ApiResponse<Payment>(
          success: false,
          message: response['message'] ?? 'Failed to initialize top-up',
        );
      }
    } catch (e) {
      return ApiResponse<Payment>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  /// Submit payment to GMPay
  static Future<ApiResponse<Map<String, dynamic>>> submitToGMPay({
    required String msisdn,
    required String amount,
    required String transactionId,
  }) async {
    try {
      final payload = {
        'msisdn': msisdn,
        'amount': amount,
        'transactionId': transactionId,
      };

      final response = await http.post(
        Uri.parse(_gmpayDepositUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: data,
          message: 'Payment submitted to GMPay',
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: data['message'] ?? 'Failed to submit payment to GMPay',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  /// Check payment status from GMPay
  static Future<ApiResponse<Map<String, dynamic>>> checkGMPayStatus({
    required String transactionId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_gmpayStatusUrl/$transactionId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: data,
          message: 'Status retrieved successfully',
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: data['message'] ?? 'Failed to check payment status',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  /// Verify payment status from our backend
  static Future<ApiResponse<Payment>> verifyPayment({
    required String transactionId,
  }) async {
    try {
      final response = await ApiService().get(
        ApiConfig.verifyPayment + '/$transactionId',
      );

      if (response['success'] == true) {
        return ApiResponse<Payment>(
          success: true,
          data: Payment.fromJson(response['data']),
          message: response['message'] ?? 'Payment verified successfully',
        );
      } else {
        return ApiResponse<Payment>(
          success: false,
          message: response['message'] ?? 'Failed to verify payment',
        );
      }
    } catch (e) {
      return ApiResponse<Payment>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  /// Get payment history
  static Future<ApiResponse<List<Payment>>> getPaymentHistory() async {
    try {
      final response = await ApiService().get(
        ApiConfig.paymentHistory,
      );

      if (response['success'] == true) {
        final List<Payment> payments = (response['data'] as List)
            .map((json) => Payment.fromJson(json))
            .toList();
            
        return ApiResponse<List<Payment>>(
          success: true,
          data: payments,
          message: response['message'] ?? 'Payment history retrieved successfully',
        );
      } else {
        return ApiResponse<List<Payment>>(
          success: false,
          message: response['message'] ?? 'Failed to get payment history',
        );
      }
    } catch (e) {
      return ApiResponse<List<Payment>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  /// Get wallet statistics
  static Future<ApiResponse<Map<String, dynamic>>> getWalletStats() async {
    try {
      final response = await ApiService().get(
        ApiConfig.walletStats,
      );

      if (response['success'] == true) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response['data'],
          message: response['message'] ?? 'Wallet stats retrieved successfully',
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response['message'] ?? 'Failed to get wallet stats',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  /// Format phone number for GMPay (add 256 prefix if not present)
  static String formatPhoneForGMPay(String phone) {
    // Remove any spaces or special characters
    phone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (phone.startsWith('256')) {
      return phone;
    } else if (phone.startsWith('07') && phone.length == 10) {
      return '256' + phone.substring(1);
    } else if (phone.startsWith('0') && phone.length == 10) {
      return '256' + phone.substring(1);
    } else {
      // If it doesn't match expected format, try to format it
      if (phone.length == 9 && !phone.startsWith('0')) {
        return '256' + phone;
      } else if (phone.length == 10 && phone.startsWith('0')) {
        return '256' + phone.substring(1);
      } else {
        return phone; // Return as is if we can't format it
      }
    }
  }

  /// Calculate tokens from amount (1 token = 100 UGX)
  static int calculateTokens(double amount) {
    return (amount / 100).round();
  }

  /// Calculate amount from tokens
  static double calculateAmount(int tokens) {
    return tokens * 100.0;
  }

  /// Validate minimum top-up amount (500 UGX = 5 tokens)
  static bool isValidTopUpAmount(double amount) {
    return amount >= 500.0;
  }

  /// Validate phone number format (07XXXXXXXX)
  static bool isValidPhoneNumber(String phone) {
    // Remove any spaces or special characters
    phone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check if it's a valid Ugandan mobile number
    return phone.startsWith('07') && phone.length == 10;
  }

  /// Check pending transactions (triggers cron job)
  static Future<ApiResponse<Map<String, dynamic>>> checkPendingTransactions() async {
    try {
      final response = await ApiService().get(
        ApiConfig.checkPendingTransactions,
      );

      if (response['success'] == true) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response['data'],
          message: response['message'] ?? 'Pending transactions checked successfully',
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response['message'] ?? 'Failed to check pending transactions',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
} 