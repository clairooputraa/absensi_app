// lib/screens/mass_attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/attendance_provider.dart';
import '../helpers/sound_helper.dart';

class MassAttendanceScreen extends StatefulWidget {
  const MassAttendanceScreen({super.key});

  @override
  State<MassAttendanceScreen> createState() => _MassAttendanceScreenState();
}

class _MassAttendanceScreenState extends State<MassAttendanceScreen> {
  bool _isLoading = false;
  String _selectedMethod = 'Manual';
  String _selectedStatus = 'Hadir';
  Map<String, dynamic> _stats = {};

  final List<String> _methods = [
    'Manual',
    'Face',
    'RFID',
    'Selfie',
    'Fingerprint',
    'GPS'
  ];
  final List<String> _statuses = ['Hadir', 'Izin', 'Sakit', 'Alpha'];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    // 🔥 PERBAIKAN: Panggil loadDailyStats, bukan getDailyStats
    final stats = await attendanceProvider.loadDailyStats(DateTime.now());
    setState(() {
      _stats = stats;
    });
  }

  Future<void> _doMassAttendance() async {
    setState(() => _isLoading = true);

    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);

    // 🔥 PERBAIKAN: Panggil massAttendance dengan benar
    final result = await attendanceProvider.massAttendance(
      method: _selectedMethod,
      status: _selectedStatus,
      timestamp: DateTime.now(),
    );

    setState(() => _isLoading = false);

    if (result.success > 0) {
      await SoundHelper.playSuccess();
    }

    // Tampilkan hasil
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hasil Absensi Massal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ Berhasil: ${result.success} user',
                style: const TextStyle(color: Colors.green)),
            if (result.failed > 0) ...[
              const SizedBox(height: 8),
              Text('❌ Gagal: ${result.failed} user',
                  style: const TextStyle(color: Colors.red)),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Detail error:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount:
                        result.errors.length > 5 ? 5 : result.errors.length,
                    itemBuilder: (context, index) {
                      return Text(
                        '• ${result.errors[index]}',
                        style: const TextStyle(fontSize: 11, color: Colors.red),
                      );
                    },
                  ),
                ),
              ],
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadStats();
            },
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
        title: const Text('Absensi Massal'),
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
            onPressed: _loadStats,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistik Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2196F3),
                    const Color(0xFF1565C0),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'Statistik Hari Ini',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                          'Total',
                          _stats['total_users']?.toString() ?? '0',
                          Icons.people),
                      _buildStatItem(
                          'Hadir',
                          _stats['hadir']?.toString() ?? '0',
                          Icons.check_circle),
                      _buildStatItem(
                          'Belum',
                          _stats['belum_absen']?.toString() ?? '0',
                          Icons.hourglass_empty),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Izin', _stats['izin']?.toString() ?? '0',
                          Icons.description),
                      _buildStatItem('Sakit',
                          _stats['sakit']?.toString() ?? '0', Icons.sick),
                      _buildStatItem('Alpha',
                          _stats['alpha']?.toString() ?? '0', Icons.cancel),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Form Absensi Massal
            Container(
              padding: const EdgeInsets.all(20),
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Form Absensi Massal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pilih Metode
                  DropdownButtonFormField<String>(
                    value: _selectedMethod,
                    decoration: const InputDecoration(
                      labelText: 'Metode Absensi',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code_scanner),
                    ),
                    items: _methods.map((method) {
                      return DropdownMenuItem(
                          value: method, child: Text(method));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedMethod = value!);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Pilih Status
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.assignment_turned_in),
                    ),
                    items: _statuses.map((status) {
                      return DropdownMenuItem(
                          value: status, child: Text(status));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedStatus = value!);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Tombol Submit
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _doMassAttendance,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.people_alt),
                      label: Text(
                        _isLoading ? 'Memproses...' : 'Absen Massal',
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
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Informasi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Absensi massal akan mencatat kehadiran untuk SEMUA user sekaligus. User yang sudah absen hari ini tidak akan terduplikasi.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}
