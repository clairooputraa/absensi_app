// lib/models/attendance_record.dart
class AttendanceRecord {
  final DateTime date;
  final String status;
  final String checkInTime;
  final String? checkOutTime;

  AttendanceRecord({
    required this.date,
    required this.status,
    required this.checkInTime,
    this.checkOutTime,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: DateTime.parse(json['date']),
      status: json['status'],
      checkInTime: json['check_in_time'],
      checkOutTime: json['check_out_time'],
    );
  }
}
