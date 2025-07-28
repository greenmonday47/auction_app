import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _user != null;

  // Initialize auth state from storage
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    
    if (_token != null) {
      await _loadUserProfile();
    }
  }

  // Register new user
  Future<bool> register({
    required String phone,
    required String pin,
    required String name,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.register(
        phone: phone,
        pin: pin,
        name: name,
      );

      if (response['success']) {
        _user = User.fromJson(response['data']['user']);
        _token = response['data']['token'];
        await _saveToken();
        _setLoading(false);
        return true;
      } else {
        _setError(response['message']);
        return false;
      }
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      return false;
    }
  }

  // Login user
  Future<bool> login({
    required String phone,
    required String pin,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      print('Attempting login with phone: $phone');
      final response = await _apiService.login(
        phone: phone,
        pin: pin,
      );

      print('Login response: $response');

      if (response['success']) {
        _user = User.fromJson(response['data']['user']);
        _token = response['data']['token'];
        await _saveToken();
        _setLoading(false);
        return true;
      } else {
        _setError(response['message']);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      _setError('Login failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Load user profile
  Future<void> _loadUserProfile() async {
    if (_token == null) return;

    try {
      final response = await _apiService.getUserProfile(_token!);
      if (response['success']) {
        _user = User.fromJson(response['data']);
        notifyListeners();
      }
    } catch (e) {
      // Silent fail - user might need to login again
    }
  }

  // Update user profile
  Future<bool> updateProfile({required String name}) async {
    if (_token == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.updateProfile(
        name: name,
        token: _token!,
      );

      if (response['success']) {
        _user = User.fromJson(response['data']);
        _setLoading(false);
        return true;
      } else {
        _setError(response['message']);
        return false;
      }
    } catch (e) {
      _setError('Update failed: ${e.toString()}');
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    _user = null;
    _token = null;
    await _clearToken();
    notifyListeners();
  }

  // Save token to storage
  Future<void> _saveToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
  }

  // Clear token from storage
  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
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