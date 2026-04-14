import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/user_provider.dart';
import '../services/fingerprint_service.dart';
import '../helpers/sound_helper.dart';

class FingerprintAttendanceScreen extends StatefulWidget {
  const FingerprintAttendanceScreen({super.key});

  @override
  State<FingerprintAttendanceScreen> createState() =>
      _FingerprintAttendanceScreenState();
}

class _FingerprintAttendanceScreenState
    extends State<FingerprintAttendanceScreen> {
  final FingerprintService _fingerprintService = FingerprintService();
  bool _isProcessing = false;
  String _status = 'Siap';
  bool _isSupported = true;

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  Future<void> _checkSupport() async {
    final supported = await _fingerprintService.isDeviceSupported();
    setState(() {
      _isSupported = supported;
      if (!supported) {
        _status = 'Perangkat tidak mendukung fingerprint';
      }
    });
  }

  Future<void> _startFingerprintAttendance() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _status = 'Tempelkan jari pada sensor...';
    });

    try {
      final isAuthenticated = await _fingerprintService.authenticate();

      if (isAuthenticated) {
        _status = 'Verifikasi berhasil, memproses absensi...';

        final attendanceProvider =
            Provider.of<AttendanceProvider>(context, listen: false);
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        final success = await attendanceProvider.markAttendance(
          userId: userProvider.currentUser!.id,
          method: 'Sidik Jari',
          status: 'Hadir',
          timestamp: DateTime.now(),
        );

        if (success) {
          await SoundHelper.playSuccess();
          _showSuccessDialog();
        } else {
          await SoundHelper.playError();
          _showErrorDialog('Absensi gagal, coba lagi');
        }
      } else {
        await SoundHelper.playError();
        _showErrorDialog('Verifikasi fingerprint gagal');
        setState(() {
          _status = 'Verifikasi gagal, coba lagi';
        });
      }
    } catch (e) {
      await SoundHelper.playError();
      _showErrorDialog('Error: $e');
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.fingerprint, size: 60, color: Colors.green),
        content: const Text('Absensi Sidik Jari Berhasil!'),
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

  void _showErrorDialog(String message) {
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: const Text('Absensi Sidik Jari'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: _isProcessing
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: _isProcessing
                      ? [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  Icons.fingerprint,
                  size: 100,
                  color: _isProcessing ? Colors.blue : Colors.green,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _status,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Tempelkan jari Anda pada sensor fingerprint',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing || !_isSupported
                      ? null
                      : _startFingerprintAttendance,
                  icon: Icon(_isProcessing
                      ? Icons.hourglass_empty
                      : Icons.fingerprint),
                  label: Text(
                    _isProcessing ? 'Memproses...' : 'Tempelkan Jari',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (!_isSupported)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Perangkat Anda tidak mendukung fingerprint',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
