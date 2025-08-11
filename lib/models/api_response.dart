class ApiResponse<T> {
  final bool success;
  final T? data;
  final String message;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    required this.message,
    this.statusCode,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      data: json['data'] != null ? fromJson(json['data']) : null,
      message: json['message'] ?? '',
      statusCode: json['status_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'message': message,
      'status_code': statusCode,
    };
  }

  // Helper methods
  bool get hasData => data != null;
  bool get isSuccess => success;
  bool get isError => !success;
} 