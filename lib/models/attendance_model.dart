import 'package:absensi_app/screens/camera_selfie_screen.dart';
import 'package:absensi_app/screens/face_attendance_screen.dart';
import 'package:absensi_app/screens/fingerprint_attendance_screen.dart';
import 'package:absensi_app/screens/rfid_attendance_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/user_provider.dart';
import '../helpers/sound_helper.dart';
import '/screens/camera_selfie_screen.dart';
import '/screens/face_attendance_screen.dart';
import '/screens/fingerprint_attendance_screen.dart';
import '/screens/rfid_attendance_screen.dart';

class AttendanceMethodScreen extends StatelessWidget {
  const AttendanceMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // PERUBAHAN: Gunakan getActiveMethodsForUser berdasarkan role
    final user = userProvider.currentUser;
    final methods =
        attendanceProvider.getActiveMethodsForUser(user?.role ?? 'User');
    final isPetugas = user?.role == 'Petugas';

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: const Text('Pilih Metode Absensi'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: methods.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.settings,
                    size: 64,
                    color: isDark ? Colors.white54 : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada metode absensi yang diaktifkan',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isPetugas)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to profile settings
                        Navigator.pushNamed(context, '/profile');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                      ),
                      child: const Text('Atur Metode Absensi'),
                    ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: methods.length,
              itemBuilder: (context, index) {
                final method = methods[index];
                return _buildMethodCard(
                  context,
                  method['name'],
                  method['icon'],
                  method['color'],
                  isDark,
                );
              },
            ),
    );
  }

  Widget _buildMethodCard(
    BuildContext context,
    String name,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => _handleAttendance(context, name),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getMethodDescription(name),
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getMethodDescription(String method) {
    switch (method) {
      case 'Wajah':
        return 'Scan wajah untuk absen';
      case 'Selfie':
        return 'Ambil foto selfie';
      case 'RFID':
        return 'Tempel kartu RFID';
      case 'Sidik Jari':
        return 'Scan sidik jari';
      case 'GPS':
        return 'Lokasi saat ini';
      default:
        return 'Pilih metode absensi';
    }
  }

  void _handleAttendance(BuildContext context, String method) async {
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    switch (method) {
      case 'Wajah':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FaceAttendanceScreen()),
        );
        break;
      case 'Selfie':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CameraSelfieScreen()),
        );
        break;
      case 'RFID':
        // Buka halaman RFID
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RFIDAttendanceScreen()),
        );
        break;
      case 'Sidik Jari':
        // Buka halaman Fingerprint
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const FingerprintAttendanceScreen()),
        );
        break;
      case 'GPS':
        await _simpleAttendance(context, 'GPS');
        break;
      default:
        await _simpleAttendance(context, method);
        break;
    }
  }

  Future<void> _simpleAttendance(BuildContext context, String method) async {
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final success = await attendanceProvider.markAttendance(
      userId: userProvider.currentUser!.id,
      method: method,
      status: 'Hadir',
      timestamp: DateTime.now(),
    );

    if (success) {
      await SoundHelper.playSuccess();
      _showSuccessDialog(context, method);
    } else {
      await SoundHelper.playError();
      _showErrorDialog(context, 'Absensi $method gagal, coba lagi');
    }
  }

  void _showSuccessDialog(BuildContext context, String method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, size: 60, color: Colors.green),
        content: Text('Absen via $method berhasil!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Kembali ke halaman sebelumnya
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
}
