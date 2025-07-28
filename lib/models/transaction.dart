enum TransactionStatus {
  pending,
  approved,
  rejected,
}

class Transaction {
  final int id;
  final int userId;
  final double amount;
  final int tokens;
  final TransactionStatus status;
  final String createdAt;
  final String? updatedAt;
  final String? note;
  
  // Formatted fields from API
  final String? amountFormatted;
  final String? createdAtFormatted;
  final String? updatedAtFormatted;

  Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.tokens,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.note,
    this.amountFormatted,
    this.createdAtFormatted,
    this.updatedAtFormatted,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      tokens: int.tryParse(json['tokens'].toString()) ?? 0,
      status: _parseStatus(json['status']),
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'],
      note: json['note'],
      amountFormatted: json['amount_formatted'],
      createdAtFormatted: json['created_at_formatted'],
      updatedAtFormatted: json['updated_at_formatted'],
    );
  }

  static TransactionStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return TransactionStatus.approved;
      case 'rejected':
        return TransactionStatus.rejected;
      case 'pending':
      default:
        return TransactionStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'tokens': tokens,
      'status': status.name,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'note': note,
      'amount_formatted': amountFormatted,
      'created_at_formatted': createdAtFormatted,
      'updated_at_formatted': updatedAtFormatted,
    };
  }

  String get statusText {
    switch (status) {
      case TransactionStatus.approved:
        return 'Approved';
      case TransactionStatus.rejected:
        return 'Rejected';
      case TransactionStatus.pending:
        return 'Pending';
    }
  }

  bool get isPending => status == TransactionStatus.pending;
  bool get isApproved => status == TransactionStatus.approved;
  bool get isRejected => status == TransactionStatus.rejected;
} 