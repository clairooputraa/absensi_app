// lib/services/local_storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/offline_attendance.dart';

class LocalStorageService {
  static const String _attendanceKey = 'local_attendance';
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // 🔥 SIMPAN KE LOCAL (PRIORITAS UTAMA)
  Future<void> saveAttendance(OfflineAttendance attendance) async {
    final List<String>? existing = _prefs.getStringList(_attendanceKey);
    final List<String> list = existing ?? [];

    // Cek apakah sudah ada
    final index = list.indexWhere((item) {
      final data = jsonDecode(item);
      return data['id'] == attendance.id;
    });

    if (index != -1) {
      list[index] = jsonEncode(attendance.toJson());
    } else {
      list.add(jsonEncode(attendance.toJson()));
    }

    await _prefs.setStringList(_attendanceKey, list);
  }

  // Ambil semua data local
  Future<List<OfflineAttendance>> getAllAttendance() async {
    final List<String>? list = _prefs.getStringList(_attendanceKey);
    if (list == null || list.isEmpty) return [];

    return list
        .map((item) => OfflineAttendance.fromJson(jsonDecode(item)))
        .toList();
  }

  // Ambil data yang belum di-sync
  Future<List<OfflineAttendance>> getUnsyncedAttendance() async {
    final all = await getAllAttendance();
    return all.where((a) => !a.isSynced).toList();
  }

  // Tandai sebagai sudah di-sync
  Future<void> markAsSynced(String id) async {
    final all = await getAllAttendance();
    final index = all.indexWhere((a) => a.id == id);

    if (index != -1) {
      all[index].isSynced = true;
      all[index].syncedAt = DateTime.now();

      final List<String> list = all.map((a) => jsonEncode(a.toJson())).toList();
      await _prefs.setStringList(_attendanceKey, list);
    }
  }

  // Hapus data yang sudah di-sync (opsional)
  Future<void> removeSyncedData() async {
    final all = await getAllAttendance();
    final unsynced = all.where((a) => !a.isSynced).toList();

    final List<String> list =
        unsynced.map((a) => jsonEncode(a.toJson())).toList();
    await _prefs.setStringList(_attendanceKey, list);
  }

  // Hapus semua data
  Future<void> clearAll() async {
    await _prefs.remove(_attendanceKey);
  }

  // Hitung jumlah data local
  Future<int> count() async {
    final all = await getAllAttendance();
    return all.length;
  }
}
