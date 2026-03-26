class UserProfile {
  final String id;
  final String? name;
  final String? phone;
  final bool isEarlybird;
  final int freeAnalysesRemaining;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    this.name,
    this.phone,
    this.isEarlybird = false,
    this.freeAnalysesRemaining = 0,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      isEarlybird: json['is_earlybird'] ?? false,
      freeAnalysesRemaining: json['free_analyses_remaining'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get canAnalyze => freeAnalysesRemaining > 0;
}
