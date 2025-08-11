enum PaymentStatus {
  pending,
  success,
  failed,
  approved,
  rejected,
}

class Payment {
  final int id;
  final int userId;
  final double amount;
  final int tokens;
  final PaymentStatus status;
  final String? transactionId;
  final String? paymentType;
  final String? note;
  final String createdAt;
  final String? updatedAt;
  
  // GMPay specific fields
  final String? msisdn;
  final String? gmpayStatus;
  final String? reference;

  Payment({
    required this.id,
    required this.userId,
    required this.amount,
    required this.tokens,
    required this.status,
    this.transactionId,
    this.paymentType,
    this.note,
    required this.createdAt,
    this.updatedAt,
    this.msisdn,
    this.gmpayStatus,
    this.reference,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      tokens: int.tryParse(json['tokens'].toString()) ?? 0,
      status: _parseStatus(json['status']),
      transactionId: json['transaction_id'],
      paymentType: json['payment_type'],
      note: json['note'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'],
      msisdn: json['msisdn'],
      gmpayStatus: json['gmpay_status'],
      reference: json['reference'],
    );
  }

  static PaymentStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'success':
        return PaymentStatus.success;
      case 'approved':
        return PaymentStatus.approved;
      case 'failed':
      case 'rejected':
        return PaymentStatus.failed;
      case 'pending':
      default:
        return PaymentStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'tokens': tokens,
      'status': status.name,
      'transaction_id': transactionId,
      'payment_type': paymentType,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'msisdn': msisdn,
      'gmpay_status': gmpayStatus,
      'reference': reference,
    };
  }

  String get statusText {
    switch (status) {
      case PaymentStatus.success:
        return 'Success';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.approved:
        return 'Approved';
      case PaymentStatus.rejected:
        return 'Rejected';
    }
  }

  bool get isPending => status == PaymentStatus.pending;
  bool get isSuccess => status == PaymentStatus.success;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isApproved => status == PaymentStatus.approved;
  bool get isRejected => status == PaymentStatus.rejected;

  // Helper method to get formatted amount
  String get amountFormatted => 'UGX ${amount.toStringAsFixed(0)}';
  
  // Helper method to get tokens formatted
  String get tokensFormatted => '$tokens tokens';
} 