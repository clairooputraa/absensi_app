import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/user_provider.dart';
import '../helpers/sound_helper.dart';
import 'camera_selfie_screen.dart';
import 'face_attendance_screen.dart';
import 'rfid_attendance_screen.dart';
import 'gps_attendance_screen.dart';
import 'fingerprint_attendance_screen.dart';
import 'mass_attendance_screen.dart';

class AttendanceMethodScreen extends StatelessWidget {
  const AttendanceMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = themeProvider.isDarkMode;

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
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.settings,
                        size: 64, color: Color(0xFF2196F3)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada metode absensi yang diaktifkan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),
                  if (isPetugas)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/profile');
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Atur Metode Absensi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                ],
              ),
            )
          : Column(
              children: [
                // Grid metode absensi
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: methods.length,
                    itemBuilder: (context, index) {
                      final method = methods[index];
                      return _buildMethodCard(context, method['name'],
                          method['icon'], method['color'], isDark);
                    },
                  ),
                ),

                // 🔥 TOMBOL ABSENSI MASSAL UNTUK ADMIN
                if (isPetugas) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.people_alt,
                              color: Colors.orange, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Absensi Massal',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Absen semua user sekaligus',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MassAttendanceScreen()),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: const Text('Buka'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildMethodCard(BuildContext context, String name, IconData icon,
      Color color, bool isDark) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (name.hashCode % 300)),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () => _handleAttendance(context, name),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)]
                  : [Colors.white, color.withValues(alpha: 0.5)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  _getMethodDescription(name),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
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
        return 'Tempel kartu RFID ke reader';
      case 'Sidik Jari':
        return 'Tempelkan jari ke sensor';
      case 'GPS':
        return 'Absen dengan lokasi GPS';
      default:
        return 'Pilih metode absensi';
    }
  }

  void _handleAttendance(BuildContext context, String method) {
    switch (method) {
      case 'Wajah':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const FaceAttendanceScreen()));
        break;
      case 'Selfie':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CameraSelfieScreen()));
        break;
      case 'RFID':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const RFIDAttendanceScreen()));
        break;
      case 'Sidik Jari':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const FingerprintAttendanceScreen()));
        break;
      case 'GPS':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const GPSAttendanceScreen()));
        break;
      default:
        _simpleAttendance(context, method);
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
      if (!context.mounted) return;
      _showSuccessDialog(context, method);
    } else {
      await SoundHelper.playError();
      if (!context.mounted) return;
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
              Navigator.pop(context);
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
