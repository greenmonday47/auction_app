import 'bid.dart';

class Auction {
  final int id;
  final String itemName;
  final String description;
  final String? image;
  final DateTime startTime;
  final DateTime endTime;
  final double startingPrice;
  final bool isCompleted;
  final int? winnerId;
  final String? winnerName;
  final String? winnerPhone;
  final String createdAt;
  
  // Formatted fields from API
  final String? startingPriceFormatted;
  final String? startTimeFormatted;
  final String? endTimeFormatted;
  final double? currentHighestBid;
  final String? currentHighestBidFormatted;
  final int? totalBids;
  final double? finalBid;
  final String? finalBidFormatted;
  final List<Bid>? bids;
  final bool? isLive;

  Auction({
    required this.id,
    required this.itemName,
    required this.description,
    this.image,
    required this.startTime,
    required this.endTime,
    required this.startingPrice,
    required this.isCompleted,
    this.winnerId,
    this.winnerName,
    this.winnerPhone,
    required this.createdAt,
    this.startingPriceFormatted,
    this.startTimeFormatted,
    this.endTimeFormatted,
    this.currentHighestBid,
    this.currentHighestBidFormatted,
    this.totalBids,
    this.finalBid,
    this.finalBidFormatted,
    this.bids,
    this.isLive,
  });

  factory Auction.fromJson(Map<String, dynamic> json) {
    return Auction(
      id: int.tryParse(json['id'].toString()) ?? 0,
      itemName: json['item_name'] ?? '',
      description: json['description'] ?? '',
      image: json['image'],
      startTime: DateTime.parse(json['start_time'] ?? DateTime.now().toIso8601String()),
      endTime: DateTime.parse(json['end_time'] ?? DateTime.now().toIso8601String()),
      startingPrice: (json['starting_price'] ?? 0).toDouble(),
      isCompleted: json['is_completed'] == 1 || json['is_completed'] == true,
      winnerId: json['winner_id'] != null ? int.tryParse(json['winner_id'].toString()) : null,
      winnerName: json['winner_name'],
      winnerPhone: json['winner_phone'],
      createdAt: json['created_at'] ?? '',
      startingPriceFormatted: json['starting_price_formatted'],
      startTimeFormatted: json['start_time_formatted'],
      endTimeFormatted: json['end_time_formatted'],
      currentHighestBid: json['current_highest_bid']?.toDouble(),
      currentHighestBidFormatted: json['current_highest_bid_formatted'],
      totalBids: json['total_bids'] != null ? int.tryParse(json['total_bids'].toString()) : null,
      finalBid: json['final_bid']?.toDouble(),
      finalBidFormatted: json['final_bid_formatted'],
      bids: json['bids'] != null 
          ? List<Bid>.from(json['bids'].map((x) => Bid.fromJson(x)))
          : null,
      isLive: json['is_live'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_name': itemName,
      'description': description,
      'image': image,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'starting_price': startingPrice,
      'is_completed': isCompleted,
      'winner_id': winnerId,
      'winner_name': winnerName,
      'winner_phone': winnerPhone,
      'created_at': createdAt,
      'starting_price_formatted': startingPriceFormatted,
      'start_time_formatted': startTimeFormatted,
      'end_time_formatted': endTimeFormatted,
      'current_highest_bid': currentHighestBid,
      'current_highest_bid_formatted': currentHighestBidFormatted,
      'total_bids': totalBids,
      'final_bid': finalBid,
      'final_bid_formatted': finalBidFormatted,
      'bids': bids?.map((x) => x.toJson()).toList() ?? [],
      'is_live': isLive,
    };
  }

  // Helper methods
  bool get isUpcoming => startTime.isAfter(DateTime.now());
  bool get isCurrentlyLive => startTime.isBefore(DateTime.now()) && endTime.isAfter(DateTime.now());
  bool get hasEnded => endTime.isBefore(DateTime.now());
  
  String get status {
    if (isCompleted) return 'Completed';
    if (isCurrentlyLive) return 'Live';
    if (isUpcoming) return 'Upcoming';
    return 'Ended';
  }

  double get currentBid => currentHighestBid ?? startingPrice;
} 