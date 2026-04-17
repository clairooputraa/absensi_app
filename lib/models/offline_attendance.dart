// lib/models/offline_attendance.dart
class OfflineAttendance {
  final String id;
  final String userId;
  final String userName;
  final String method;
  final String status;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final String? uid;
  bool isSynced;
  DateTime? syncedAt;

  OfflineAttendance({
    required this.id,
    required this.userId,
    required this.userName,
    required this.method,
    required this.status,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.uid,
    this.isSynced = false,
    this.syncedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'method': method,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'photoUrl': photoUrl,
        'uid': uid,
        'isSynced': isSynced,
        'syncedAt': syncedAt?.toIso8601String(),
      };

  factory OfflineAttendance.fromJson(Map<String, dynamic> json) {
    return OfflineAttendance(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      method: json['method'],
      status: json['status'],
      timestamp: DateTime.parse(json['timestamp']),
      latitude: json['latitude'],
      longitude: json['longitude'],
      photoUrl: json['photoUrl'],
      uid: json['uid'],
      isSynced: json['isSynced'] ?? false,
      syncedAt:
          json['syncedAt'] != null ? DateTime.parse(json['syncedAt']) : null,
    );
  }
}
