import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../main.dart'; // import global supabaseClient

// ==================== OFFLINE ATTENDANCE MODEL ====================
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

class AttendanceProvider extends ChangeNotifier {
  bool _faceEnabled = true;
  bool _rfidEnabled = true;
  bool _selfieEnabled = true;
  bool _fingerprintEnabled = true;
  bool _gpsEnabled = true;

  List<Map<String, dynamic>> _attendanceHistory = [];
  Map<String, int> _weeklyStats = {};
  List<Map<String, dynamic>> _allUsers = [];
  Map<String, dynamic> _dailyStats = {};

  // OFFLINE PROPERTIES
  late SharedPreferences _prefs;
  bool _isOnline = true;
  int _pendingSyncCount = 0;
  final Connectivity _connectivity = Connectivity();
  static const String _offlineKey = 'offline_attendance';

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
  bool get isOnline => _isOnline;
  int get pendingSyncCount => _pendingSyncCount;

  // ==================== INIT OFFLINE ====================

  Future<void> initOffline() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadOfflineCount();

    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;

    _connectivity.onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (!wasOnline && _isOnline) {
        _syncAllOfflineData();
      }
      notifyListeners();
    });

    notifyListeners();
  }

  Future<void> _loadOfflineCount() async {
    final List<String>? list = _prefs.getStringList(_offlineKey);
    _pendingSyncCount = list?.length ?? 0;
    notifyListeners();
  }

  // ==================== SETTINGS ====================

  Future<void> loadSettings() async {
    try {
      final response =
          await supabaseClient.from('settings').select().maybeSingle();
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
      final existing =
          await supabaseClient.from('settings').select().maybeSingle();
      if (existing != null) {
        await supabaseClient.from('settings').update({
          'face_enabled': _faceEnabled,
          'rfid_enabled': _rfidEnabled,
          'selfie_enabled': _selfieEnabled,
          'fingerprint_enabled': _fingerprintEnabled,
          'gps_enabled': _gpsEnabled,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existing['id']);
      } else {
        await supabaseClient.from('settings').insert({
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
    String userName = await _getUserName(userId);
    final attendanceId = '${DateTime.now().millisecondsSinceEpoch}_$userId';

    final offlineData = OfflineAttendance(
      id: attendanceId,
      userId: userId,
      userName: userName,
      method: method,
      status: status,
      timestamp: timestamp,
      uid: uid,
      latitude: latitude,
      longitude: longitude,
      photoUrl: photoUrl,
      isSynced: false,
    );

    await _saveToLocal(offlineData);

    _attendanceHistory.insert(0, {
      'user_id': userId,
      'user_name': userName,
      'method': method,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'is_synced': false,
    });

    await _updateLocalStats(userId);
    notifyListeners();

    if (_isOnline) {
      _sendToServer(attendanceId);
    }

    return true;
  }

  Future<void> _saveToLocal(OfflineAttendance attendance) async {
    final List<String>? existing = _prefs.getStringList(_offlineKey);
    final List<String> list = existing ?? [];
    list.add(jsonEncode(attendance.toJson()));
    await _prefs.setStringList(_offlineKey, list);
    _pendingSyncCount = list.length;
    notifyListeners();
  }

  Future<void> _sendToServer(String attendanceId) async {
    final List<String>? list = _prefs.getStringList(_offlineKey);
    if (list == null) return;

    int index = -1;
    OfflineAttendance? attendance;

    for (int i = 0; i < list.length; i++) {
      final data = OfflineAttendance.fromJson(jsonDecode(list[i]));
      if (data.id == attendanceId) {
        index = i;
        attendance = data;
        break;
      }
    }

    if (attendance == null) return;
    if (attendance.isSynced) return;

    try {
      await supabaseClient.from('attendance').insert({
        'user_id': attendance.userId,
        'user_name': attendance.userName,
        'uid': attendance.uid,
        'method': attendance.method,
        'status': attendance.status,
        'latitude': attendance.latitude,
        'longitude': attendance.longitude,
        'photo_url': attendance.photoUrl,
        'timestamp': attendance.timestamp.toIso8601String(),
      });

      attendance.isSynced = true;
      attendance.syncedAt = DateTime.now();
      list[index] = jsonEncode(attendance.toJson());
      await _prefs.setStringList(_offlineKey, list);

      int newCount = list.where((item) {
        final data = OfflineAttendance.fromJson(jsonDecode(item));
        return !data.isSynced;
      }).length;
      _pendingSyncCount = newCount;

      notifyListeners();
      debugPrint('✅ Synced: ${attendance.userName} - ${attendance.method}');
    } catch (e) {
      debugPrint('❌ Sync failed: $e');
    }
  }

  Future<void> _syncAllOfflineData() async {
    if (!_isOnline) return;

    final List<String>? list = _prefs.getStringList(_offlineKey);
    if (list == null) return;

    for (int i = 0; i < list.length; i++) {
      final data = OfflineAttendance.fromJson(jsonDecode(list[i]));
      if (!data.isSynced) {
        await _sendToServer(data.id);
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }

  Future<void> syncNow() async {
    if (!_isOnline) {
      debugPrint('Tidak ada koneksi internet');
      return;
    }
    await _syncAllOfflineData();
  }

  Future<String> _getUserName(String userId) async {
    try {
      final cachedUser = _allUsers.cast<Map<String, dynamic>?>().firstWhere(
            (u) => u?['id'] == userId,
            orElse: () => null,
          );
      if (cachedUser != null) {
        return cachedUser['name'] ?? 'Unknown';
      }
    } catch (e) {}

    try {
      final response = await supabaseClient
          .from('users')
          .select('name')
          .eq('id', userId)
          .maybeSingle();
      return response?['name'] ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _updateLocalStats(String userId) async {
    final List<String>? list = _prefs.getStringList(_offlineKey);
    if (list == null) return;

    final now = DateTime.now();
    final startOfWeek =
        DateTime(now.year, now.month, now.day - now.weekday + 1);

    int hadir = 0, izin = 0, sakit = 0, alpha = 0;
    for (var item in list) {
      final data = OfflineAttendance.fromJson(jsonDecode(item));
      if (data.userId == userId && data.timestamp.isAfter(startOfWeek)) {
        switch (data.status) {
          case 'Hadir':
            hadir++;
            break;
          case 'Izin':
            izin++;
            break;
          case 'Sakit':
            sakit++;
            break;
          case 'Alpha':
            alpha++;
            break;
        }
      }
    }

    _weeklyStats = {
      'hadir': hadir,
      'izin': izin,
      'sakit': sakit,
      'alpha': alpha,
    };
    notifyListeners();
  }

  // ==================== HISTORY & STATS ====================

  Future<void> loadAttendanceHistory(String userId) async {
    final List<String>? list = _prefs.getStringList(_offlineKey);
    if (list != null && list.isNotEmpty) {
      final List<Map<String, dynamic>> filtered = [];
      for (var item in list) {
        final data = OfflineAttendance.fromJson(jsonDecode(item));
        if (data.userId == userId) {
          filtered.add({
            'user_id': data.userId,
            'user_name': data.userName,
            'method': data.method,
            'status': data.status,
            'timestamp': data.timestamp.toIso8601String(),
            'is_synced': data.isSynced,
          });
        }
      }
      _attendanceHistory = filtered;
      notifyListeners();
    }
  }

  Future<void> loadWeeklyStats(String userId) async {
    await _updateLocalStats(userId);

    if (_isOnline) {
      try {
        final now = DateTime.now();
        final startOfWeek =
            DateTime(now.year, now.month, now.day - now.weekday + 1);
        final response = await supabaseClient
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
  }

  Future<void> loadAllUsers() async {
    try {
      final response = await supabaseClient
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

      final response = await supabaseClient
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

  // ==================== METHODS FOR UI ====================

  List<Map<String, dynamic>> getActiveMethods() {
    final List<Map<String, dynamic>> methods = [];
    if (_faceEnabled)
      methods
          .add({'name': 'Wajah', 'icon': Icons.face, 'color': Colors.orange});
    if (_rfidEnabled)
      methods.add({'name': 'RFID', 'icon': Icons.nfc, 'color': Colors.purple});
    if (_selfieEnabled)
      methods.add(
          {'name': 'Selfie', 'icon': Icons.camera_alt, 'color': Colors.blue});
    if (_fingerprintEnabled)
      methods.add({
        'name': 'Sidik Jari',
        'icon': Icons.fingerprint,
        'color': Colors.green
      });
    if (_gpsEnabled)
      methods.add(
          {'name': 'GPS', 'icon': Icons.location_on, 'color': Colors.teal});
    return methods;
  }

  List<Map<String, dynamic>> getActiveMethodsForUser(String userRole) {
    final List<Map<String, dynamic>> methods = [];
    if (_faceEnabled)
      methods
          .add({'name': 'Wajah', 'icon': Icons.face, 'color': Colors.orange});
    if (_selfieEnabled)
      methods.add(
          {'name': 'Selfie', 'icon': Icons.camera_alt, 'color': Colors.blue});
    if (_gpsEnabled)
      methods.add(
          {'name': 'GPS', 'icon': Icons.location_on, 'color': Colors.teal});
    if (userRole == 'Petugas') {
      if (_rfidEnabled)
        methods
            .add({'name': 'RFID', 'icon': Icons.nfc, 'color': Colors.purple});
      if (_fingerprintEnabled)
        methods.add({
          'name': 'Sidik Jari',
          'icon': Icons.fingerprint,
          'color': Colors.green
        });
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

  // ==================== METHOD UNTUK UI ====================

  Future<Map<String, dynamic>> getTodayAttendanceHistory() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      await loadAllUsers();
      final allUsers = List<Map<String, dynamic>>.from(_allUsers);

      List<Map<String, dynamic>> attendanceData = [];
      if (_isOnline) {
        try {
          final response = await supabaseClient
              .from('attendance')
              .select('user_id, user_name, method, status, timestamp')
              .gte('timestamp', startOfDay.toIso8601String())
              .lt('timestamp', endOfDay.toIso8601String());
          attendanceData = List<Map<String, dynamic>>.from(response);
        } catch (e) {}
      }

      final List<String>? offlineList = _prefs.getStringList(_offlineKey);
      final Map<String, Map<String, dynamic>> attendedMap = {};

      for (var data in attendanceData) {
        attendedMap[data['user_id']] = {
          'method': data['method'],
          'status': data['status'],
          'timestamp': data['timestamp'],
        };
      }

      if (offlineList != null) {
        for (var item in offlineList) {
          final data = OfflineAttendance.fromJson(jsonDecode(item));
          if (data.timestamp.isAfter(startOfDay) &&
              data.timestamp.isBefore(endOfDay)) {
            attendedMap[data.userId] = {
              'method': data.method,
              'status': data.status,
              'timestamp': data.timestamp.toIso8601String(),
            };
          }
        }
      }

      final List<Map<String, dynamic>> attended = [];
      final List<Map<String, dynamic>> notAttended = [];

      for (var user in allUsers) {
        final userId = user['id'];
        final userName = user['name'] ?? 'Unknown';
        if (attendedMap.containsKey(userId)) {
          attended.add({
            'user_id': userId,
            'user_name': userName,
            'method': attendedMap[userId]!['method'],
            'status': attendedMap[userId]!['status'],
            'timestamp': attendedMap[userId]!['timestamp'],
          });
        } else {
          notAttended.add({'user_id': userId, 'user_name': userName});
        }
      }

      return {
        'total_users': allUsers.length,
        'attended_count': attended.length,
        'not_attended_count': notAttended.length,
        'attended': attended,
        'not_attended': notAttended,
      };
    } catch (e) {
      return {
        'total_users': 0,
        'attended_count': 0,
        'not_attended_count': 0,
        'attended': [],
        'not_attended': []
      };
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistory(
      {int limit = 50}) async {
    try {
      if (_isOnline) {
        final response = await supabaseClient
            .from('attendance')
            .select('*, users!inner(name)')
            .order('timestamp', ascending: false)
            .limit(limit);
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      return [];
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

    List<Map<String, dynamic>> existingAttendance = [];
    if (_isOnline) {
      try {
        final response = await supabaseClient
            .from('attendance')
            .select('user_id')
            .gte('timestamp', startOfDay.toIso8601String())
            .lt('timestamp', endOfDay.toIso8601String());
        existingAttendance = List<Map<String, dynamic>>.from(response);
      } catch (e) {}
    }

    final alreadyAttended =
        existingAttendance.map((json) => json['user_id'] as String).toSet();

    for (var user in users) {
      final userId = user['id'];
      final userName = user['name'] ?? 'Unknown';

      if (alreadyAttended.contains(userId)) {
        success++;
        continue;
      }

      try {
        if (_isOnline) {
          await supabaseClient.from('attendance').insert({
            'user_id': userId,
            'user_name': userName,
            'method': method,
            'status': status,
            'timestamp': now.toIso8601String(),
            'latitude': latitude,
            'longitude': longitude,
          });
        } else {
          await markAttendance(
              userId: userId, method: method, status: status, timestamp: now);
        }
        success++;
      } catch (e) {
        failed++;
        errors.add('$userName: ${e.toString()}');
      }
    }

    await loadDailyStats(now);
    return MassAttendanceResult(
        success: success, failed: failed, errors: errors);
  }
}

// MassAttendanceResult class
class MassAttendanceResult {
  final int success;
  final int failed;
  final List<String> errors;
  MassAttendanceResult(
      {required this.success, required this.failed, required this.errors});
}
