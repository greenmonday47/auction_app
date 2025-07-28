import 'package:flutter/material.dart';
import '../models/auction.dart';
import '../models/bid.dart';
import '../utils/api_service.dart';

class AuctionProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Auction> _upcomingAuctions = [];
  List<Auction> _liveAuctions = [];
  List<Auction> _completedAuctions = [];
  Auction? _selectedAuction;
  bool _isLoading = false;
  String? _error;

  List<Auction> get upcomingAuctions => _upcomingAuctions;
  List<Auction> get liveAuctions => _liveAuctions;
  List<Auction> get completedAuctions => _completedAuctions;
  Auction? get selectedAuction => _selectedAuction;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load upcoming auctions
  Future<void> loadUpcomingAuctions() async {
    _setLoading(true);
    _clearError();

    try {
      print('Loading upcoming auctions...');
      final response = await _apiService.getUpcomingAuctions();
      print('Upcoming auctions response: $response');
      
      if (response['success']) {
        final data = response['data'];
        print('Upcoming auctions data: $data');
        
        if (data is List) {
          _upcomingAuctions = data
              .map((json) => Auction.fromJson(json))
              .toList();
          print('Parsed ${_upcomingAuctions.length} upcoming auctions');
          
          // Debug image URLs
          for (var auction in _upcomingAuctions) {
            print('Auction ${auction.id} image: ${auction.image}');
          }
        } else {
          print('Expected List but got: ${data.runtimeType}');
          _setError('Invalid data format for upcoming auctions');
        }
        _setLoading(false);
      } else {
        print('API returned error: ${response['message']}');
        _setError(response['message']);
      }
    } catch (e) {
      print('Error loading upcoming auctions: $e');
      _setError('Failed to load upcoming auctions: ${e.toString()}');
    }
  }

  // Load live auctions
  Future<void> loadLiveAuctions() async {
    _setLoading(true);
    _clearError();

    try {
      print('Loading live auctions...');
      final response = await _apiService.getLiveAuctions();
      print('Live auctions response: $response');
      
      if (response['success']) {
        final data = response['data'];
        print('Live auctions data: $data');
        
        if (data is List) {
          _liveAuctions = data
              .map((json) => Auction.fromJson(json))
              .toList();
          print('Parsed ${_liveAuctions.length} live auctions');
          
          // Debug image URLs
          for (var auction in _liveAuctions) {
            print('Live auction ${auction.id} image: ${auction.image}');
          }
        } else {
          print('Expected List but got: ${data.runtimeType}');
          _setError('Invalid data format for live auctions');
        }
        _setLoading(false);
      } else {
        print('API returned error: ${response['message']}');
        _setError(response['message']);
      }
    } catch (e) {
      print('Error loading live auctions: $e');
      _setError('Failed to load live auctions: ${e.toString()}');
    }
  }

  // Load completed auctions
  Future<void> loadCompletedAuctions() async {
    _setLoading(true);
    _clearError();

    try {
      print('Loading completed auctions...');
      final response = await _apiService.getCompletedAuctions();
      print('Completed auctions response: $response');
      
      if (response['success']) {
        final data = response['data'];
        print('Completed auctions data: $data');
        
        if (data is List) {
          _completedAuctions = data
              .map((json) => Auction.fromJson(json))
              .toList();
          print('Parsed ${_completedAuctions.length} completed auctions');
        } else {
          print('Expected List but got: ${data.runtimeType}');
          _setError('Invalid data format for completed auctions');
        }
        _setLoading(false);
      } else {
        print('API returned error: ${response['message']}');
        _setError(response['message']);
      }
    } catch (e) {
      print('Error loading completed auctions: $e');
      _setError('Failed to load completed auctions: ${e.toString()}');
    }
  }

  // Load auction detail
  Future<void> loadAuctionDetail(int auctionId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getAuctionDetail(auctionId);
      if (response['success']) {
        _selectedAuction = Auction.fromJson(response['data']);
        _setLoading(false);
      } else {
        _setError(response['message']);
      }
    } catch (e) {
      _setError('Failed to load auction details: ${e.toString()}');
    }
  }

  // Place a bid
  Future<bool> placeBid({
    required int auctionId,
    required double amount,
    required String token,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.placeBid(
        auctionId: auctionId,
        amount: amount,
        token: token,
      );

      if (response['success']) {
        // Refresh auction details after successful bid
        await loadAuctionDetail(auctionId);
        await loadLiveAuctions(); // Refresh live auctions list
        _setLoading(false);
        return true;
      } else {
        _setError(response['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to place bid: ${e.toString()}');
      return false;
    }
  }

  // Refresh all auction data
  Future<void> refreshAllAuctions() async {
    _setLoading(true);
    _clearError();
    
    try {
      print('Refreshing all auctions...');
      
      // Load all auctions without setting individual loading states
      final upcomingResponse = await _apiService.getUpcomingAuctions();
      final liveResponse = await _apiService.getLiveAuctions();
      final completedResponse = await _apiService.getCompletedAuctions();
      
      if (upcomingResponse['success']) {
        final data = upcomingResponse['data'];
        if (data is List) {
          _upcomingAuctions = data.map((json) => Auction.fromJson(json)).toList();
        }
      }
      
      if (liveResponse['success']) {
        final data = liveResponse['data'];
        if (data is List) {
          _liveAuctions = data.map((json) => Auction.fromJson(json)).toList();
        }
      }
      
      if (completedResponse['success']) {
        final data = completedResponse['data'];
        if (data is List) {
          _completedAuctions = data.map((json) => Auction.fromJson(json)).toList();
        }
      }
      
      print('All auctions refreshed successfully');
      _setLoading(false);
    } catch (e) {
      print('Error refreshing auctions: $e');
      _setError('Failed to refresh auctions: ${e.toString()}');
    }
  }

  // Refresh auction data when countdown expires
  Future<void> refreshExpiredAuctions() async {
    final now = DateTime.now();
    
    // Check if any live auctions have ended
    bool hasExpiredLive = false;
    for (var auction in _liveAuctions) {
      if (auction.endTime.isBefore(now)) {
        hasExpiredLive = true;
        break;
      }
    }
    
    // Check if any upcoming auctions have started
    bool hasStartedUpcoming = false;
    for (var auction in _upcomingAuctions) {
      if (auction.startTime.isBefore(now)) {
        hasStartedUpcoming = true;
        break;
      }
    }
    
    // Refresh data if needed
    if (hasExpiredLive || hasStartedUpcoming) {
      print('Refreshing auctions due to expired countdowns');
      await refreshAllAuctions();
    }
  }

  // Clear selected auction
  void clearSelectedAuction() {
    _selectedAuction = null;
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