// lib/models/offline_attendance.dart
class OfflineAttendance {
  final String id;
  final String userId;
  final String method;
  final String status;
  final DateTime timestamp;
  final bool isSynced;
  final String? photoPath;

  OfflineAttendance({
    required this.id,
    required this.userId,
    required this.method,
    required this.status,
    required this.timestamp,
    required this.isSynced,
    this.photoPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'method': method,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'is_synced': isSynced,
      'photo_path': photoPath,
    };
  }

  factory OfflineAttendance.fromJson(Map<String, dynamic> json) {
    return OfflineAttendance(
      id: json['id'],
      userId: json['user_id'],
      method: json['method'],
      status: json['status'],
      timestamp: DateTime.parse(json['timestamp']),
      isSynced: json['is_synced'] ?? false,
      photoPath: json['photo_path'],
    );
  }
}
