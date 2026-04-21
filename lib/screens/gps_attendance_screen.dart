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
  String? _shortAddress;
  double? _latitude;
  double? _longitude;
  double? _accuracy;

  // Koordinat kantor
  final double _officeLat = -7.9822;
  final double _officeLon = 112.6304;
  final double _radius = 100;

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
      _status = 'Mendapatkan lokasi... Pastikan GPS aktif dan di luar ruangan';
    });

    try {
      final position = await _gpsService.getCurrentLocation();

      if (position != null) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _accuracy = position.accuracy;
        });

        final fullAddress = await _gpsService.getAddressFromLatLng(
          position.latitude,
          position.longitude,
        );
        final shortAddr = await _gpsService.getShortAddress(
          position.latitude,
          position.longitude,
        );

        setState(() {
          _currentAddress = fullAddress;
          _shortAddress = shortAddr;
        });

        if (position.accuracy > 50) {
          setState(() {
            _status =
                '⚠️ Akurasi GPS rendah (${position.accuracy.toStringAsFixed(0)} meter). Coba ke luar ruangan.';
          });
        } else {
          setState(() {
            _status =
                '✅ Lokasi ditemukan (akurasi: ${position.accuracy.toStringAsFixed(0)} meter)';
          });
        }
      } else {
        setState(() {
          _status = 'Gagal mendapatkan lokasi';
        });
        _showErrorDialog(
            'Gagal mendapatkan lokasi. Pastikan GPS aktif dan Anda di luar ruangan.');
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

  Future<void> _refreshLocation() async {
    await _getCurrentLocation();
  }

  Future<void> _takeAttendance() async {
    if (_latitude == null || _longitude == null) {
      _showErrorDialog('Lokasi belum didapatkan');
      return;
    }

    if (_accuracy != null && _accuracy! > 50) {
      _showErrorDialog(
          'Akurasi GPS terlalu rendah (${_accuracy!.toStringAsFixed(0)} meter).\n'
          'Pergi ke luar ruangan dan refresh lokasi.');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Memproses absensi...';
    });

    try {
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
    double distance = _gpsService.calculateDistance(
        _latitude!, _longitude!, _officeLat, _officeLon);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.location_on, size: 60, color: Colors.green),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✅ Absensi GPS Berhasil!'),
            const SizedBox(height: 12),
            if (_shortAddress != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text('📍 Lokasi Absen',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_shortAddress!,
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('📏 Jarak: ${distance.toStringAsFixed(0)} m',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                if (_accuracy != null)
                  Text(
                    '🎯 Akurasi: ${_accuracy!.toStringAsFixed(0)} m',
                    style: TextStyle(
                        fontSize: 11,
                        color: _accuracy! > 50 ? Colors.red : Colors.green),
                  ),
              ],
            ),
          ],
        ),
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

    // Hitung jarak dan cek jangkauan
    double distanceToOffice = 0;
    bool isInRange = false;
    if (_latitude != null && _longitude != null) {
      distanceToOffice = _gpsService.calculateDistance(
          _latitude!, _longitude!, _officeLat, _officeLon);
      isInRange = distanceToOffice <= _radius;
    }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLocation,
            tooltip: 'Refresh Lokasi',
          ),
        ],
      ),
      // 🔥 TAMBAHKAN SingleChildScrollView UNTUK MENCEGAH OVERFLOW
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                if (_latitude != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.location_on,
                                color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text('📍 Detail Lokasi Anda',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Alamat Lengkap',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(_currentAddress ?? 'Mengambil alamat...',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_shortAddress != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Lokasi (Singkat)',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.place,
                                        size: 14, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Expanded(
                                        child: Text(_shortAddress!,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Latitude',
                                        style: TextStyle(
                                            fontSize: 10, color: Colors.grey)),
                                    Text(_latitude!.toStringAsFixed(6),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Longitude',
                                        style: TextStyle(
                                            fontSize: 10, color: Colors.grey)),
                                    Text(_longitude!.toStringAsFixed(6),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(
                                  '📏 Jarak: ${distanceToOffice.toStringAsFixed(0)} m',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.blue)),
                            ),
                            if (_accuracy != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _accuracy! > 50
                                      ? Colors.red.withOpacity(0.1)
                                      : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '🎯 Akurasi: ${_accuracy!.toStringAsFixed(0)} m',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: _accuracy! > 50
                                          ? Colors.red
                                          : Colors.green),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              const Icon(Icons.info,
                                  size: 16, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Radius kantor: $_radius meter',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.orange),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isInRange
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isInRange
                                      ? '✅ Dalam Jangkauan'
                                      : '❌ Di Luar Jangkauan',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          isInRange ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                if (_latitude == null)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _getCurrentLocation,
                      icon: Icon(_isLoading
                          ? Icons.hourglass_empty
                          : Icons.my_location),
                      label: Text(_isLoading
                          ? 'Mendapatkan lokasi...'
                          : 'Dapatkan Lokasi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (_latitude != null)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _takeAttendance,
                      icon: Icon(_isLoading
                          ? Icons.hourglass_empty
                          : Icons.check_circle),
                      label:
                          Text(_isLoading ? 'Memproses...' : 'Absen Sekarang'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
