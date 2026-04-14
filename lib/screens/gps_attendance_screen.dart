import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/user_provider.dart';
import '../services/gps_service.dart';
import '../helpers/sound_helper.dart';

class GPSAttendanceScreen extends StatefulWidget {
  const GPSAttendanceScreen({super.key});

  @override
  State<GPSAttendanceScreen> createState() => _GPSAttendanceScreenState();
}

class _GPSAttendanceScreenState extends State<GPSAttendanceScreen> {
  final GPSService _gpsService = GPSService();
  bool _isLoading = false;
  bool _hasPermission = false;
  String _status = 'Mengambil izin lokasi...';
  String? _currentAddress;
  double? _latitude;
  double? _longitude;

  // Koordinat kantor (GANTI dengan koordinat kantor Anda yang sebenarnya)
  // Contoh: SMKN 8 Malang
  final double _officeLat = -7.9822; // Ganti dengan latitude kantor Anda
  final double _officeLon = 112.6304; // Ganti dengan longitude kantor Anda
  final double _radius = 100; // Radius 100 meter

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    setState(() {
      _status = 'Memeriksa izin lokasi...';
    });

    bool hasPermission = await _gpsService.checkPermission();
    setState(() {
      _hasPermission = hasPermission;
      if (hasPermission) {
        _status = 'Izin lokasi diberikan, siap absen';
      } else {
        _status = 'Izin lokasi diperlukan untuk absensi GPS';
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    if (!_hasPermission) {
      await _checkPermission();
      if (!_hasPermission) {
        _showErrorDialog('Izin lokasi diperlukan untuk absensi GPS');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _status = 'Mendapatkan lokasi...';
    });

    try {
      final position = await _gpsService.getCurrentLocation();

      if (position != null) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });

        final address = await _gpsService.getAddressFromLatLng(
          position.latitude,
          position.longitude,
        );

        setState(() {
          _currentAddress = address;
          _status = 'Lokasi ditemukan';
        });
      } else {
        setState(() {
          _status = 'Gagal mendapatkan lokasi';
        });
        _showErrorDialog('Gagal mendapatkan lokasi. Pastikan GPS aktif.');
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
      _showErrorDialog('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _takeAttendance() async {
    if (_latitude == null || _longitude == null) {
      _showErrorDialog('Lokasi belum didapatkan');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Memproses absensi...';
    });

    try {
      // Cek apakah dalam radius kantor
      bool isInOffice = _gpsService.isWithinRadius(
        _latitude!,
        _longitude!,
        _officeLat,
        _officeLon,
        _radius,
      );

      double distance = _gpsService.calculateDistance(
        _latitude!,
        _longitude!,
        _officeLat,
        _officeLon,
      );

      if (!isInOffice) {
        await SoundHelper.playError();
        _showErrorDialog(
            'Anda berada di luar radius absensi!\nJarak dari kantor: ${distance.toStringAsFixed(0)} meter\nRadius yang diizinkan: $_radius meter');
        setState(() {
          _status = 'Di luar radius absensi';
          _isLoading = false;
        });
        return;
      }

      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final success = await attendanceProvider.markAttendance(
        userId: userProvider.currentUser!.id,
        method: 'GPS',
        status: 'Hadir',
        timestamp: DateTime.now(),
        latitude: _latitude,
        longitude: _longitude,
      );

      if (success) {
        await SoundHelper.playSuccess();
        _showSuccessDialog();
      } else {
        await SoundHelper.playError();
        _showErrorDialog('Absensi GPS gagal, coba lagi');
      }
    } catch (e) {
      await SoundHelper.playError();
      _showErrorDialog('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
        if (_latitude != null) {
          _status = 'Siap absen';
        }
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.location_on, size: 60, color: Colors.green),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Absensi GPS Berhasil!'),
            const SizedBox(height: 8),
            if (_currentAddress != null)
              Text(
                _currentAddress!,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 4),
            Text(
              'Jarak ke kantor: ${_gpsService.calculateDistance(_latitude!, _longitude!, _officeLat, _officeLon).toStringAsFixed(0)} meter',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Kembali ke home
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
        title: const Text('Absensi GPS'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon GPS
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: _hasPermission
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on,
                        size: 80,
                        color: _hasPermission ? Colors.green : Colors.orange,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Status
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

              // Lokasi
              if (_latitude != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '📍 Lokasi Anda',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_currentAddress != null)
                        Text(
                          _currentAddress!,
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                        style: const TextStyle(
                            fontSize: 11, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Jarak ke kantor: ${_gpsService.calculateDistance(_latitude!, _longitude!, _officeLat, _officeLon).toStringAsFixed(0)} meter',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Tombol Dapatkan Lokasi
              if (_latitude == null)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _getCurrentLocation,
                    icon: Icon(
                        _isLoading ? Icons.hourglass_empty : Icons.my_location),
                    label: Text(
                      _isLoading ? 'Mendapatkan lokasi...' : 'Dapatkan Lokasi',
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

              const SizedBox(height: 16),

              // Tombol Absen
              if (_latitude != null)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _takeAttendance,
                    icon: Icon(_isLoading
                        ? Icons.hourglass_empty
                        : Icons.check_circle),
                    label: Text(
                      _isLoading ? 'Memproses...' : 'Absen Sekarang',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              // Tombol Refresh
              if (_latitude != null)
                TextButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Lokasi'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
