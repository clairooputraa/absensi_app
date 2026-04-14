import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _faceEnabled = true;
  bool _rfidEnabled = true;
  bool _selfieEnabled = true;
  bool _fingerprintEnabled = true;
  bool _gpsEnabled = true;

  List<Map<String, dynamic>> _attendanceHistory = [];
  Map<String, int> _weeklyStats = {};
  List<Map<String, dynamic>> _allUsers = [];
  Map<String, dynamic> _dailyStats = {};

  // Getters
  bool get faceEnabled => _faceEnabled;
  bool get rfidEnabled => _rfidEnabled;
  bool get selfieEnabled => _selfieEnabled;
  bool get fingerprintEnabled => _fingerprintEnabled;
  bool get gpsEnabled => _gpsEnabled;
  List<Map<String, dynamic>> get attendanceHistory => _attendanceHistory;
  Map<String, int> get weeklyStats => _weeklyStats;
  List<Map<String, dynamic>> get allUsers => _allUsers;
  Map<String, dynamic> get dailyStats => _dailyStats;

  // ==================== SETTINGS ====================

  Future<void> loadSettings() async {
    try {
      final response = await _supabase.from('settings').select().maybeSingle();
      if (response != null) {
        _faceEnabled = response['face_enabled'] ?? true;
        _rfidEnabled = response['rfid_enabled'] ?? true;
        _selfieEnabled = response['selfie_enabled'] ?? true;
        _fingerprintEnabled = response['fingerprint_enabled'] ?? true;
        _gpsEnabled = response['gps_enabled'] ?? true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> saveSettings() async {
    try {
      final existing = await _supabase.from('settings').select().maybeSingle();
      if (existing != null) {
        await _supabase.from('settings').update({
          'face_enabled': _faceEnabled,
          'rfid_enabled': _rfidEnabled,
          'selfie_enabled': _selfieEnabled,
          'fingerprint_enabled': _fingerprintEnabled,
          'gps_enabled': _gpsEnabled,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existing['id']);
      } else {
        await _supabase.from('settings').insert({
          'face_enabled': _faceEnabled,
          'rfid_enabled': _rfidEnabled,
          'selfie_enabled': _selfieEnabled,
          'fingerprint_enabled': _fingerprintEnabled,
          'gps_enabled': _gpsEnabled,
        });
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  // ==================== ATTENDANCE METHODS ====================

  Future<bool> markAttendance({
    required String userId,
    required String method,
    required String status,
    required DateTime timestamp,
    String? uid,
    double? latitude,
    double? longitude,
    String? photoUrl,
  }) async {
    try {
      final userResponse = await _supabase
          .from('users')
          .select('name')
          .eq('id', userId)
          .maybeSingle();

      final userName = userResponse?['name'] ?? 'Unknown';

      await _supabase.from('attendance').insert({
        'user_id': userId,
        'user_name': userName,
        'uid': uid,
        'method': method,
        'status': status,
        'latitude': latitude,
        'longitude': longitude,
        'photo_url': photoUrl,
        'timestamp': timestamp.toIso8601String(),
      });

      await loadAttendanceHistory(userId);
      await loadWeeklyStats(userId);
      await loadDailyStats(DateTime.now());

      return true;
    } catch (e) {
      debugPrint('Error marking attendance: $e');
      return false;
    }
  }

  // ==================== HISTORY & STATS ====================

  Future<void> loadAttendanceHistory(String userId) async {
    try {
      // 🔥 PERBAIKAN: Pakai filter di dalam select
      final response = await _supabase
          .from('attendance')
          .select('*')
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      _attendanceHistory = List<Map<String, dynamic>>.from(response);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> loadWeeklyStats(String userId) async {
    try {
      final now = DateTime.now();
      final startOfWeek =
          DateTime(now.year, now.month, now.day - now.weekday + 1);

      // 🔥 PERBAIKAN: Pakai filter langsung
      final response = await _supabase
          .from('attendance')
          .select('status')
          .eq('user_id', userId)
          .gte('timestamp', startOfWeek.toIso8601String());

      _weeklyStats = {
        'hadir': response.where((a) => a['status'] == 'Hadir').length,
        'izin': response.where((a) => a['status'] == 'Izin').length,
        'sakit': response.where((a) => a['status'] == 'Sakit').length,
        'alpha': response.where((a) => a['status'] == 'Alpha').length,
      };
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading weekly stats: $e');
    }
  }

  Future<void> loadAllUsers() async {
    try {
      // 🔥 PERBAIKAN: Pakai filter langsung
      final response = await _supabase
          .from('users')
          .select('*')
          .eq('is_active', true)
          .order('name');

      _allUsers = List<Map<String, dynamic>>.from(response);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading users: $e');
    }
  }

  Future<Map<String, dynamic>> loadDailyStats(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      await loadAllUsers();
      final totalUsers = _allUsers.length;

      // 🔥 PERBAIKAN: Pakai filter langsung
      final response = await _supabase
          .from('attendance')
          .select('status')
          .gte('timestamp', startOfDay.toIso8601String())
          .lt('timestamp', endOfDay.toIso8601String());

      final hadir = response.where((a) => a['status'] == 'Hadir').length;
      final izin = response.where((a) => a['status'] == 'Izin').length;
      final sakit = response.where((a) => a['status'] == 'Sakit').length;
      final alpha = response.where((a) => a['status'] == 'Alpha').length;
      final totalAbsen = hadir + izin + sakit + alpha;

      _dailyStats = {
        'total_users': totalUsers,
        'hadir': hadir,
        'izin': izin,
        'sakit': sakit,
        'alpha': alpha,
        'total_absen': totalAbsen,
        'belum_absen': totalUsers - totalAbsen,
      };

      notifyListeners();
      return _dailyStats;
    } catch (e) {
      debugPrint('Error loading daily stats: $e');
      return {};
    }
  }

  Future<MassAttendanceResult> massAttendance({
    required String method,
    required String status,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
  }) async {
    int success = 0;
    int failed = 0;
    List<String> errors = [];

    final now = timestamp ?? DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    await loadAllUsers();
    final users = List<Map<String, dynamic>>.from(_allUsers);

    // 🔥 PERBAIKAN: Pakai filter langsung
    final existingAttendance = await _supabase
        .from('attendance')
        .select('user_id')
        .gte('timestamp', startOfDay.toIso8601String())
        .lt('timestamp', endOfDay.toIso8601String());

    final alreadyAttended = existingAttendance
        .map<String>((json) => json['user_id'] as String)
        .toSet();

    for (var user in users) {
      final userId = user['id'];
      final userName = user['name'] ?? 'Unknown';

      if (alreadyAttended.contains(userId)) {
        success++;
        continue;
      }

      try {
        await _supabase.from('attendance').insert({
          'user_id': userId,
          'user_name': userName,
          'method': method,
          'status': status,
          'timestamp': now.toIso8601String(),
          'latitude': latitude,
          'longitude': longitude,
        });
        success++;
      } catch (e) {
        failed++;
        errors.add('$userName: ${e.toString()}');
      }
    }

    await loadDailyStats(now);

    return MassAttendanceResult(
      success: success,
      failed: failed,
      errors: errors,
    );
  }

  // 🔥 METHOD GET ATTENDANCE HISTORY (TANPA filter tanggal dulu)
  Future<List<Map<String, dynamic>>> getAttendanceHistory({
    String? userId,
    int limit = 50,
  }) async {
    try {
      if (userId != null && userId.isNotEmpty) {
        final response = await _supabase
            .from('attendance')
            .select('*')
            .eq('user_id', userId)
            .order('timestamp', ascending: false)
            .limit(limit);
        return List<Map<String, dynamic>>.from(response);
      } else {
        final response = await _supabase
            .from('attendance')
            .select('*')
            .order('timestamp', ascending: false)
            .limit(limit);
        return List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      debugPrint('Error getting history: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getDailyStats(DateTime date) async {
    return await loadDailyStats(date);
  }

  // ==================== METHODS FOR UI ====================

  List<Map<String, dynamic>> getActiveMethods() {
    final List<Map<String, dynamic>> methods = [];

    if (_faceEnabled) {
      methods
          .add({'name': 'Wajah', 'icon': Icons.face, 'color': Colors.orange});
    }
    if (_rfidEnabled) {
      methods.add({'name': 'RFID', 'icon': Icons.nfc, 'color': Colors.purple});
    }
    if (_selfieEnabled) {
      methods.add(
          {'name': 'Selfie', 'icon': Icons.camera_alt, 'color': Colors.blue});
    }
    if (_fingerprintEnabled) {
      methods.add({
        'name': 'Sidik Jari',
        'icon': Icons.fingerprint,
        'color': Colors.green
      });
    }
    if (_gpsEnabled) {
      methods.add(
          {'name': 'GPS', 'icon': Icons.location_on, 'color': Colors.teal});
    }

    return methods;
  }

  List<Map<String, dynamic>> getActiveMethodsForUser(String userRole) {
    final List<Map<String, dynamic>> methods = [];

    if (userRole == 'Petugas') {
      if (_faceEnabled) {
        methods
            .add({'name': 'Wajah', 'icon': Icons.face, 'color': Colors.orange});
      }
      if (_rfidEnabled) {
        methods
            .add({'name': 'RFID', 'icon': Icons.nfc, 'color': Colors.purple});
      }
      if (_selfieEnabled) {
        methods.add(
            {'name': 'Selfie', 'icon': Icons.camera_alt, 'color': Colors.blue});
      }
      if (_fingerprintEnabled) {
        methods.add({
          'name': 'Sidik Jari',
          'icon': Icons.fingerprint,
          'color': Colors.green
        });
      }
      if (_gpsEnabled) {
        methods.add(
            {'name': 'GPS', 'icon': Icons.location_on, 'color': Colors.teal});
      }
    } else {
      if (_faceEnabled) {
        methods
            .add({'name': 'Wajah', 'icon': Icons.face, 'color': Colors.orange});
      }
      if (_selfieEnabled) {
        methods.add(
            {'name': 'Selfie', 'icon': Icons.camera_alt, 'color': Colors.blue});
      }
      if (_gpsEnabled) {
        methods.add(
            {'name': 'GPS', 'icon': Icons.location_on, 'color': Colors.teal});
      }
      if (_rfidEnabled) {
        methods
            .add({'name': 'RFID', 'icon': Icons.nfc, 'color': Colors.purple});
      }
      if (_fingerprintEnabled) {
        methods.add({
          'name': 'Sidik Jari',
          'icon': Icons.fingerprint,
          'color': Colors.green
        });
      }
    }

    return methods;
  }

  // ==================== SETTERS ====================

  void setFaceEnabled(bool value) {
    _faceEnabled = value;
    saveSettings();
    notifyListeners();
  }

  void setRfidEnabled(bool value) {
    _rfidEnabled = value;
    saveSettings();
    notifyListeners();
  }

  void setSelfieEnabled(bool value) {
    _selfieEnabled = value;
    saveSettings();
    notifyListeners();
  }

  void setFingerprintEnabled(bool value) {
    _fingerprintEnabled = value;
    saveSettings();
    notifyListeners();
  }

  void setGpsEnabled(bool value) {
    _gpsEnabled = value;
    saveSettings();
    notifyListeners();
  }
}

// 🔥 MODEL untuk hasil absensi massal
class MassAttendanceResult {
  final int success;
  final int failed;
  final List<String> errors;

  MassAttendanceResult({
    required this.success,
    required this.failed,
    required this.errors,
  });
}
