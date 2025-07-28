class Bid {
  final int id;
  final int auctionId;
  final int userId;
  final double amount;
  final int tokensUsed;
  final String createdAt;
  final String? userName;
  
  // Formatted fields from API
  final String? amountFormatted;
  final String? createdAtFormatted;

  Bid({
    required this.id,
    required this.auctionId,
    required this.userId,
    required this.amount,
    required this.tokensUsed,
    required this.createdAt,
    this.userName,
    this.amountFormatted,
    this.createdAtFormatted,
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      id: int.tryParse(json['id'].toString()) ?? 0,
      auctionId: int.tryParse(json['auction_id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      tokensUsed: int.tryParse(json['tokens_used'].toString()) ?? 0,
      createdAt: json['created_at'] ?? '',
      userName: json['user_name'],
      amountFormatted: json['amount_formatted'],
      createdAtFormatted: json['created_at_formatted'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auction_id': auctionId,
      'user_id': userId,
      'amount': amount,
      'tokens_used': tokensUsed,
      'created_at': createdAt,
      'user_name': userName,
      'amount_formatted': amountFormatted,
      'created_at_formatted': createdAtFormatted,
    };
  }
} 