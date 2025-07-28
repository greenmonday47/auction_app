class User {
  final int id;
  final String phone;
  final String name;
  final int tokens;
  final String createdAt;

  User({
    required this.id,
    required this.phone,
    required this.name,
    required this.tokens,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.tryParse(json['id'].toString()) ?? 0,
      phone: json['phone'] ?? '',
      name: json['name'] ?? '',
      tokens: int.tryParse(json['tokens'].toString()) ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'tokens': tokens,
      'created_at': createdAt,
    };
  }

  User copyWith({
    int? id,
    String? phone,
    String? name,
    int? tokens,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      tokens: tokens ?? this.tokens,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 