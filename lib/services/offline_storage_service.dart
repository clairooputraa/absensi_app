// lib/services/offline_storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/offline_attendance.dart';

class OfflineStorageService {
  static const String _key = 'offline_attendance';
  final SharedPreferences _prefs;

  OfflineStorageService(this._prefs);

  // Simpan absen offline
  Future<void> saveAttendance(OfflineAttendance attendance) async {
    final List<String>? existing = _prefs.getStringList(_key);
    final List<String> list = existing ?? [];

    list.add(jsonEncode(attendance.toJson()));
    await _prefs.setStringList(_key, list);
  }

  // Ambil semua absen offline
  Future<List<OfflineAttendance>> getAllOfflineAttendance() async {
    final List<String>? list = _prefs.getStringList(_key);
    if (list == null || list.isEmpty) return [];

    return list
        .map((item) => OfflineAttendance.fromJson(jsonDecode(item)))
        .toList();
  }

  // Hapus absen yang sudah di-sync
  Future<void> removeAttendance(String id) async {
    final List<String>? existing = _prefs.getStringList(_key);
    if (existing == null) return;

    final List<String> newList = existing.where((item) {
      final data = jsonDecode(item);
      return data['id'] != id;
    }).toList();

    await _prefs.setStringList(_key, newList);
  }

  // Hapus semua setelah sync
  Future<void> clearAllSynced() async {
    final all = await getAllOfflineAttendance();
    final unsynced = all.where((a) => !a.isSynced).toList();

    final List<String> newList =
        unsynced.map((a) => jsonEncode(a.toJson())).toList();
    await _prefs.setStringList(_key, newList);
  }

  // Cek jumlah offline data
  Future<int> getOfflineCount() async {
    final list = await getAllOfflineAttendance();
    return list.length;
  }
}
