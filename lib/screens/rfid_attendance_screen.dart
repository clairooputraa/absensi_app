import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/user_provider.dart';
import '../services/rfid_service.dart';
import '../helpers/sound_helper.dart';
import 'dart:async';

class RFIDAttendanceScreen extends StatefulWidget {
  const RFIDAttendanceScreen({super.key});

  @override
  State<RFIDAttendanceScreen> createState() => _RFIDAttendanceScreenState();
}

class _RFIDAttendanceScreenState extends State<RFIDAttendanceScreen> {
  final RFIDService _rfidService = RFIDService();
  final TextEditingController _ipController = TextEditingController();

  bool _isConnected = false;
  bool _isReading = false;
  String _status = 'Belum terhubung';
  String? _lastUID;
  List<Map<String, dynamic>> _attendanceLogs = [];
  StreamSubscription<String>? _uidSubscription;

  static const String DEFAULT_ESP32_IP = '192.168.4.1';

  @override
  void initState() {
    super.initState();
    _ipController.text = DEFAULT_ESP32_IP;
    _uidSubscription = _rfidService.uidStream.listen(_onUIDDetected);
  }

  @override
  void dispose() {
    _uidSubscription?.cancel();
    _rfidService.disconnect();
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _connectToESP32() async {
    setState(() {
      _status = 'Menghubungkan ke ESP32...';
    });

    final success = await _rfidService.connectToESP32(_ipController.text);

    setState(() {
      _isConnected = success;
      _isReading = success;
      _status = success
          ? 'Terhubung, siap membaca kartu RFID'
          : 'Gagal terhubung ke ESP32';
    });
  }

  void _onUIDDetected(String uid) async {
    setState(() {
      _lastUID = uid;
      _status = 'Kartu terdeteksi: $uid, memproses...';
    });

    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.currentUser?.id ?? 'unknown';

    final result = await _processAttendance(uid, userId);

    setState(() {
      if (result['success'] == true) {
        _status = 'Absen berhasil! ${result['name']}';
        _attendanceLogs.insert(0, {
          'uid': uid,
          'name': result['name'],
          'time': DateTime.now(),
          'status': 'Hadir',
        });
        _showSuccessDialog(result['name']);
      } else {
        _status = 'Gagal: ${result['message']}';
        _showErrorDialog(result['message']);
      }
    });

    _rfidService.sendConfirmation(result['success'] == true, uid,
        result['success'] == true ? result['name'] : '');
  }

  Future<Map<String, dynamic>> _processAttendance(
      String uid, String userId) async {
    try {
      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);

      await Future.delayed(const Duration(milliseconds: 500));

      final Map<String, Map<String, String>> registeredUIDs = {
        '12:34:56:78': {
          'name': 'Eko Santoso',
          'role': 'Petugas',
          'userId': 'user1'
        },
        'AB:CD:EF:01': {
          'name': 'Budi Santoso',
          'role': 'Siswa',
          'userId': 'user2'
        },
        'FP_12345': {'name': 'Admin', 'role': 'Petugas', 'userId': 'user3'},
      };

      if (registeredUIDs.containsKey(uid)) {
        final userData = registeredUIDs[uid]!;

        final String method = uid.startsWith('FP_') ? 'Sidik Jari' : 'RFID';

        await attendanceProvider.markAttendance(
          userId: userData['userId']!,
          method: method,
          status: 'Hadir',
          timestamp: DateTime.now(),
          uid: uid,
        );

        return {
          'success': true,
          'name': userData['name'],
          'role': userData['role'],
          'method': method,
        };
      } else {
        return {
          'success': false,
          'message': 'Kartu tidak terdaftar',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  void _disconnect() {
    _rfidService.disconnect();
    setState(() {
      _isConnected = false;
      _isReading = false;
      _status = 'Terputus';
    });
  }

  void _showSuccessDialog(String name) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, size: 60, color: Colors.green),
        content: Text('Selamat $name!\nAbsensi berhasil dicatat'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.error, size: 60, color: Colors.red),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: const Text('Absensi RFID / Fingerprint'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            _buildStatusCard(isDark),
            const SizedBox(height: 20),
            _buildConnectionPanel(isDark),
            const SizedBox(height: 20),
            if (_lastUID != null) _buildLastScanCard(isDark),
            const SizedBox(height: 20),
            _buildAttendanceLogs(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            _isConnected ? Colors.green : Colors.grey,
            _isConnected ? Colors.green.shade700 : Colors.grey.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: (_isConnected ? Colors.green : Colors.grey).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Icon(
            _isConnected ? Icons.wifi : Icons.wifi_off,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            _isConnected ? 'TERHUBUNG' : 'TERPUTUS',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _status,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (_isReading) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.nfc, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Siap membaca',
                      style: TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionPanel(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: isDark ? Colors.black12 : Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Koneksi ESP32',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ipController,
            enabled: !_isConnected,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              labelText: 'IP Address ESP32',
              hintText: 'Contoh: 192.168.4.1',
              prefixIcon: const Icon(Icons.dns),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isConnected ? _disconnect : _connectToESP32,
                  icon: Icon(_isConnected ? Icons.link_off : Icons.link),
                  label: Text(_isConnected ? 'Putuskan' : 'Hubungkan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isConnected ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLastScanCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.nfc, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Scan Terakhir',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _lastUID ?? '-',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap kartu RFID atau tempelkan jari ke sensor',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceLogs(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: isDark ? Colors.black12 : Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.history, size: 20),
              SizedBox(width: 8),
              Text(
                'Riwayat Absensi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_attendanceLogs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Belum ada riwayat absensi',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _attendanceLogs.length,
              itemBuilder: (BuildContext context, int index) {
                final Map<String, dynamic> log = _attendanceLogs[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.2),
                    child:
                        const Icon(Icons.check, color: Colors.green, size: 20),
                  ),
                  title: Text(log['name']),
                  subtitle: Text(log['uid']),
                  trailing: Text(
                    '${log['time'].hour.toString().padLeft(2, '0')}:${log['time'].minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
