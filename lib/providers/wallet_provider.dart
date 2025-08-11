import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/api_service.dart';

class WalletProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  int _tokens = 0;
  double _equivalentAmount = 0;
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  int get tokens => _tokens;
  double get equivalentAmount => _equivalentAmount;
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load wallet information
  Future<void> loadWallet(String token) async {
    _setLoading(true);
    _clearError();

    try {
      print('Loading wallet...');
      final response = await _apiService.getWallet(token);
      print('Wallet response: $response');
      
      if (response['success']) {
        final data = response['data'];
        print('Wallet data: $data');
        _tokens = data['tokens'] ?? 0;
        _equivalentAmount = (data['equivalent_amount'] ?? 0).toDouble();
        print('Parsed wallet - tokens: $_tokens, amount: $_equivalentAmount');
        _setLoading(false);
      } else {
        _setError(response['message']);
      }
    } catch (e) {
      print('Error loading wallet: $e');
      _setError('Failed to load wallet: ${e.toString()}');
    }
  }

  // Load transactions
  Future<void> loadTransactions(String token) async {
    _setLoading(true);
    _clearError();

    try {
      print('Loading transactions...');
      final response = await _apiService.getTransactions(token);
      print('Transactions response: $response');
      
      if (response['success']) {
        final data = response['data'];
        print('Transactions data: $data');
        
        if (data is List) {
          _transactions = data
              .map((json) => Transaction.fromJson(json))
              .toList();
          print('Parsed ${_transactions.length} transactions');
        } else {
          print('Expected List but got: ${data.runtimeType}');
          _setError('Invalid data format for transactions');
        }
        _setLoading(false);
      } else {
        print('API returned error: ${response['message']}');
        _setError(response['message']);
      }
    } catch (e) {
      print('Error loading transactions: $e');
      _setError('Failed to load transactions: ${e.toString()}');
    }
  }

  // Top up wallet (legacy method - now handled by payment gateway)
  Future<bool> topUp({
    required double amount,
    String? note,
    required String token,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.topUp(
        amount: amount,
        note: note,
        token: token,
      );

      if (response['success']) {
        // Refresh wallet and transactions after successful top-up
        await loadWallet(token);
        await loadTransactions(token);
        _setLoading(false);
        return true;
      } else {
        _setError(response['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to top up: ${e.toString()}');
      return false;
    }
  }

  // Initialize payment for top-up
  Future<Map<String, dynamic>> initializePayment({
    required int userId,
    required double amount,
    required String phone,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.initializeTopUp(
        userId: userId,
        amount: amount,
        phone: phone,
      );

      _setLoading(false);
      return response;
    } catch (e) {
      _setError('Failed to initialize payment: ${e.toString()}');
      return {
        'success': false,
        'message': 'Failed to initialize payment: ${e.toString()}',
      };
    }
  }

  // Verify payment status
  Future<Map<String, dynamic>> verifyPayment({
    required String transactionId,
  }) async {
    try {
      final response = await _apiService.verifyPayment(
        transactionId: transactionId,
      );
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to verify payment: ${e.toString()}',
      };
    }
  }

  // Refresh wallet data
  Future<void> refreshWallet(String token) async {
    _setLoading(true);
    _clearError();
    
    try {
      print('Refreshing wallet data...');
      
      // Load wallet and transactions without setting individual loading states
      final walletResponse = await _apiService.getWallet(token);
      final transactionsResponse = await _apiService.getTransactions(token);
      
      if (walletResponse['success']) {
        final data = walletResponse['data'];
        _tokens = data['tokens'] ?? 0;
        _equivalentAmount = (data['equivalent_amount'] ?? 0).toDouble();
      }
      
      if (transactionsResponse['success']) {
        final data = transactionsResponse['data'];
        if (data is List) {
          _transactions = data.map((json) => Transaction.fromJson(json)).toList();
        }
      }
      
      print('Wallet data refreshed successfully');
      _setLoading(false);
    } catch (e) {
      print('Error refreshing wallet: $e');
      _setError('Failed to refresh wallet: ${e.toString()}');
    }
  }

  // Update tokens (called when user places a bid)
  void updateTokens(int newTokens) {
    _tokens = newTokens;
    _equivalentAmount = _tokens * 100.0; // 1 token = 100 UGX
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
} 