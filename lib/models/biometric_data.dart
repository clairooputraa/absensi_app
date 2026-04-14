// lib/models/biometric_data.dart
class BiometricData {
  final String userId;
  final String type; // 'face', 'fingerprint'
  final String dataPath;
  final DateTime createdAt;

  BiometricData({
    required this.userId,
    required this.type,
    required this.dataPath,
    required this.createdAt,
  });

  factory BiometricData.fromJson(Map<String, dynamic> json) {
    return BiometricData(
      userId: json['user_id'],
      type: json['type'],
      dataPath: json['data_path'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'type': type,
      'data_path': dataPath,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
