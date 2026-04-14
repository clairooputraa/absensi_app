// lib/models/work_schedule_models.dart
import 'package:flutter/material.dart';

class WorkSchedule {
  final String id;
  final String userId;
  final DateTime date;
  final String shiftName;
  final DateTime checkInTime;
  final DateTime? checkOutTime;

  WorkSchedule({
    required this.id,
    required this.userId,
    required this.date,
    required this.shiftName,
    required this.checkInTime,
    this.checkOutTime,
  });

  factory WorkSchedule.fromJson(Map<String, dynamic> json) {
    return WorkSchedule(
      id: json['id'],
      userId: json['user_id'],
      date: DateTime.parse(json['date']),
      shiftName: json['shift_name'],
      checkInTime: DateTime.parse(json['check_in_time']),
      checkOutTime: json['check_out_time'] != null
          ? DateTime.parse(json['check_out_time'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'shift_name': shiftName,
      'check_in_time': checkInTime.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
    };
  }
}

class Shift {
  final String name;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const Shift({
    required this.name,
    required this.startTime,
    required this.endTime,
  });

  // Hapus const dari list shifts
  static final List<Shift> shifts = [
    const Shift(
        name: 'Pagi',
        startTime: TimeOfDay(hour: 7, minute: 0),
        endTime: TimeOfDay(hour: 15, minute: 0)),
    const Shift(
        name: 'Siang',
        startTime: TimeOfDay(hour: 15, minute: 0),
        endTime: TimeOfDay(hour: 23, minute: 0)),
    const Shift(
        name: 'Malam',
        startTime: TimeOfDay(hour: 23, minute: 0),
        endTime: TimeOfDay(hour: 7, minute: 0)),
  ];
}
