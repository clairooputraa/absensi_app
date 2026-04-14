// lib/models/attendance_log.dart
class AttendanceLog {
  final String id;
  final String userId;
  final String userName;
  final String method;
  final String status;
  final DateTime timestamp;
  final String? photoUrl;

  AttendanceLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.method,
    required this.status,
    required this.timestamp,
    this.photoUrl,
  });

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    return AttendanceLog(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? 'Unknown',
      method: json['method'],
      status: json['status'],
      timestamp: DateTime.parse(json['timestamp']),
      photoUrl: json['photo_url'],
    );
  }
}
