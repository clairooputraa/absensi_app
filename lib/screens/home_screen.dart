import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../providers/role_provider.dart';
import '../providers/user_provider.dart';
import '../providers/attendance_provider.dart';
import 'face_attendance_screen.dart';
import 'camera_selfie_screen.dart';
import 'rfid_attendance_screen.dart';
import 'fingerprint_attendance_screen.dart';
import 'gps_attendance_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _currentTime = '';
  String _currentDate = '';
  late Timer _timer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Untuk menyimpan metode presensi yang aktif
  String _activeMethod = 'wajah'; // wajah, selfie, rfid, finger, lokasi

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    _loadActiveMethod();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadActiveMethod();
  }

  Future<void> _loadActiveMethod() async {
    final prefs = await SharedPreferences.getInstance();

    String savedMethod = prefs.getString('active_absen_method') ?? '';

    if (savedMethod.isNotEmpty) {
      setState(() {
        _activeMethod = savedMethod;
      });
      print('✅ Loaded active method: $_activeMethod');
    } else {
      if (prefs.getBool('presensi_wajah') ?? true) {
        setState(() => _activeMethod = 'wajah');
      } else if (prefs.getBool('presensi_selfie') ?? false) {
        setState(() => _activeMethod = 'selfie');
      } else if (prefs.getBool('presensi_rfid') ?? false) {
        setState(() => _activeMethod = 'rfid');
      } else if (prefs.getBool('presensi_sidik_jari') ?? false) {
        setState(() => _activeMethod = 'finger');
      } else if (prefs.getBool('presensi_gps') ?? false) {
        setState(() => _activeMethod = 'lokasi');
      }
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      final days = [
        'Minggu',
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu'
      ];
      final months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember'
      ];
      _currentDate =
          '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';
      _currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _handleFABPress() async {
    switch (_activeMethod) {
      case 'wajah':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FaceAttendanceScreen(
              autoCapture: true,
              showDetectionBox: true,
            ),
          ),
        );
        break;
      case 'selfie':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CameraSelfieScreen(),
          ),
        );
        break;
      case 'rfid':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RFIDAttendanceScreen(),
          ),
        );
        break;
      case 'finger':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FingerprintAttendanceScreen(),
          ),
        );
        break;
      case 'lokasi':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const GPSAttendanceScreen(),
          ),
        );
        break;
      default:
        Navigator.pushNamed(context, '/attendance');
    }
  }

  IconData _getFABIcon() {
    switch (_activeMethod) {
      case 'wajah':
        return Icons.face;
      case 'selfie':
        return Icons.camera_alt;
      case 'rfid':
        return Icons.nfc;
      case 'finger':
        return Icons.fingerprint;
      case 'lokasi':
        return Icons.location_on;
      default:
        return Icons.camera_alt;
    }
  }

  String _getFABTooltip() {
    switch (_activeMethod) {
      case 'wajah':
        return 'Absen Wajah';
      case 'selfie':
        return 'Absen Selfie';
      case 'rfid':
        return 'Absen RFID';
      case 'finger':
        return 'Absen Sidik Jari';
      case 'lokasi':
        return 'Absen Lokasi';
      default:
        return 'Absen Sekarang';
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final roleProvider = Provider.of<RoleProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final isPetugas = roleProvider.userRole == 'Petugas';
    final user = userProvider.currentUser;

    final weeklyStats = attendanceProvider.weeklyStats;
    final totalHadir = weeklyStats['hadir'] ?? 0;
    final totalHours = totalHadir * 8;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A2A) : const Color(0xFFF0F4FF),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // Header Premium
            SliverAppBar(
              expandedHeight: 280,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2196F3),
                        const Color(0xFF1565C0),
                        const Color(0xFF0D47A1),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.person,
                                      size: 35, color: Color(0xFF2196F3)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Selamat Datang,',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 12),
                                    ),
                                    Text(
                                      user?.name ?? 'Petugas',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.white24, Colors.white12],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.work,
                                        size: 14, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Text(
                                      isPetugas ? 'Petugas' : 'Siswa',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildStatBadge(
                                  'Hadir', totalHadir.toString(), Colors.green),
                              const SizedBox(width: 12),
                              _buildStatBadge(
                                  'Izin',
                                  weeklyStats['izin']?.toString() ?? '0',
                                  Colors.orange),
                              const SizedBox(width: 12),
                              _buildStatBadge(
                                  'Sakit',
                                  weeklyStats['sakit']?.toString() ?? '0',
                                  Colors.red),
                              const SizedBox(width: 12),
                              _buildStatBadge(
                                  'Alpha',
                                  weeklyStats['alpha']?.toString() ?? '0',
                                  Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                        color: Colors.white),
                    onPressed: () => themeProvider.toggleTheme(),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.person, color: Colors.white),
                    onPressed: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                ),
              ],
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Date & Time Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF1A1A3E),
                                  const Color(0xFF0D0D2B)
                                ]
                              : [Colors.white, const Color(0xFFF8F9FF)],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black26
                                : Colors.blue.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.schedule,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentDate,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _currentTime,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  _activeMethod == 'lokasi'
                                      ? 'Lokasi'
                                      : 'Kantor',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Info Metode Aktif
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(_getFABIcon(), color: Colors.blue, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Metode Absen Aktif',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  _getFABTooltip(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'AKTIF',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Weekly Overview
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ringkasan Mingguan',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Minggu Ini',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF1A1A3E),
                                  const Color(0xFF0D0D2B)
                                ]
                              : [Colors.white, const Color(0xFFF8F9FF)],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black26
                                : Colors.blue.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Kehadiran',
                                style:
                                    TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${totalHours.toStringAsFixed(0)} Jam',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2196F3),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.trending_up,
                                        size: 14, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text('+12%',
                                        style: TextStyle(
                                            color: Colors.green, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.trending_up,
                                color: Colors.white, size: 32),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Recent Activity
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Aktivitas Terbaru',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Lihat Semua',
                              style: TextStyle(color: Color(0xFF2196F3))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF1A1A3E),
                                  const Color(0xFF0D0D2B)
                                ]
                              : [Colors.white, const Color(0xFFF8F9FF)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(Icons.history, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('Belum ada aktivitas',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // 🔥 HANYA FAB - TIDAK ADA bottomNavigationBar
      floatingActionButton: FloatingActionButton(
        onPressed: _handleFABPress,
        backgroundColor: const Color(0xFF2196F3),
        elevation: 8,
        child: Icon(_getFABIcon(), size: 32, color: Colors.white),
        tooltip: _getFABTooltip(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 🔥🔥🔥 TIDAK ADA bottomNavigationBar DI SINI! 🔥🔥🔥
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
