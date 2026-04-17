// lib/screens/attendance_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/attendance_provider.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _todayHistory = {};
  String _selectedFilter = 'semua'; // 🔥 FILTER METODE

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    
    //alur atau logika
    // 1.panggil getTodayAttendanceHistory()
    // 2.tampilkan data
    // 3.tampilkan statistik
    // 4.tampilkan filter
    // 5.tampilkan list
    setState(() => _isLoading = true);
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    _todayHistory = await provider.getTodayAttendanceHistory();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('History Absensi Hari Ini'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistik Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'Total User',
                            _todayHistory['total_users']?.toString() ?? '0',
                            Icons.people,
                          ),
                          _buildStatItem(
                            'Sudah Absen',
                            _todayHistory['attended_count']?.toString() ?? '0',
                            Icons.check_circle,
                          ),
                          _buildStatItem(
                            'Belum Absen',
                            _todayHistory['not_attended_count']?.toString() ??
                                '0',
                            Icons.hourglass_empty,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 🔥 STATISTIK METODE ABSEN
                      _buildMethodStats(),
                    ],
                  ),
                ),

                // 🔥 FILTER METODE
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Semua', 'semua'),
                        _buildFilterChip('👤 Wajah', 'wajah'),
                        _buildFilterChip('📱 RFID', 'rfid'),
                        _buildFilterChip('🤳 Selfie', 'selfie'),
                        _buildFilterChip('👆 Sidik Jari', 'fingerprint'),
                        _buildFilterChip('📍 GPS', 'gps'),
                      ],
                    ),
                  ),
                ),

                // Tab Bar
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          tabs: [
                            Tab(text: '✅ SUDAH ABSEN'),
                            Tab(text: '⏳ BELUM ABSEN'),
                          ],
                          labelColor: Color(0xFF2196F3),
                          unselectedLabelColor: Colors.grey,
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildAttendedList(),
                              _buildNotAttendedList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  // 🔥 STATISTIK BERDASARKAN METODE
  Widget _buildMethodStats() {
    final attended = _todayHistory['attended'] as List? ?? [];

    int wajah = 0, rfid = 0, selfie = 0, fingerprint = 0, gps = 0;

    for (var item in attended) {
      final method = (item['method'] ?? '').toLowerCase();
      if (method == 'wajah' || method == 'face') {
        wajah++;
      } else if (method == 'rfid') {
        rfid++;
      } else if (method == 'selfie') {
        selfie++;
      } else if (method == 'sidik jari' || method == 'fingerprint') {
        fingerprint++;
      } else if (method == 'gps') {
        gps++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Statistik Metode Absen',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMethodChip('👤', wajah, Colors.orange, 'Wajah'),
              _buildMethodChip('📱', rfid, Colors.purple, 'RFID'),
              _buildMethodChip('🤳', selfie, Colors.blue, 'Selfie'),
              _buildMethodChip('👆', fingerprint, Colors.green, 'Fingerprint'),
              _buildMethodChip('📍', gps, Colors.teal, 'GPS'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodChip(String icon, int count, Color color, String label) {
    return Tooltip(
      message: '$label: $count orang',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Text(icon, style: TextStyle(color: color, fontSize: 16)),
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? value : 'semua';
          });
        },
        backgroundColor: Colors.grey.withOpacity(0.2),
        selectedColor: const Color(0xFF2196F3),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildAttendedList() {
    List attended = _todayHistory['attended'] as List? ?? [];

    // 🔥 FILTER BERDASARKAN METODE
    if (_selectedFilter != 'semua') {
      attended = attended.where((item) {
        final method = (item['method'] ?? '').toLowerCase();
        if (_selectedFilter == 'wajah') {
          return method == 'wajah' || method == 'face';
        }
        if (_selectedFilter == 'rfid') return method == 'rfid';
        if (_selectedFilter == 'selfie') return method == 'selfie';
        if (_selectedFilter == 'fingerprint') {
          return method == 'sidik jari' || method == 'fingerprint';
        }
        if (_selectedFilter == 'gps') return method == 'gps';
        return true;
      }).toList();
    }

    if (attended.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'semua'
                  ? 'Belum ada yang absen'
                  : 'Tidak ada absen dengan metode ini',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: attended.length,
      itemBuilder: (context, index) {
        final item = attended[index];
        return _buildAttendanceCard(item);
      },
    );
  }

  Widget _buildNotAttendedList() {
    final notAttended = _todayHistory['not_attended'] as List? ?? [];

    if (notAttended.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('Semua sudah absen!', style: TextStyle(color: Colors.green)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: notAttended.length,
      itemBuilder: (context, index) {
        final item = notAttended[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.2),
              child: const Icon(Icons.access_time, color: Colors.red),
            ),
            title: Text(
              item['user_name'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Belum melakukan absensi'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'BELUM',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 🔥 CARD ABSENSI DENGAN METODE
  Widget _buildAttendanceCard(Map<String, dynamic> item) {
    final method = item['method'] ?? 'Unknown';
    final status = item['status'] ?? 'Hadir';
    final timestamp = item['timestamp'];

    // 🔥 TAMPILAN ICON BERDASARKAN METODE
    IconData methodIcon;
    Color methodColor;
    String methodName;

    switch (method.toLowerCase()) {
      case 'wajah':
      case 'face':
        methodIcon = Icons.face;
        methodColor = Colors.orange;
        methodName = 'Face Recognition';
        break;
      case 'rfid':
        methodIcon = Icons.nfc;
        methodColor = Colors.purple;
        methodName = 'Kartu RFID';
        break;
      case 'selfie':
        methodIcon = Icons.camera_alt;
        methodColor = Colors.blue;
        methodName = 'Selfie';
        break;
      case 'sidik jari':
      case 'fingerprint':
        methodIcon = Icons.fingerprint;
        methodColor = Colors.green;
        methodName = 'Sidik Jari';
        break;
      case 'gps':
        methodIcon = Icons.location_on;
        methodColor = Colors.teal;
        methodName = 'GPS';
        break;
      default:
        methodIcon = Icons.check_circle;
        methodColor = Colors.grey;
        methodName = method;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: methodColor.withOpacity(0.2),
          child: Icon(methodIcon, color: methodColor),
        ),
        title: Text(
          item['user_name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: methodColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                methodName,
                style: TextStyle(color: methodColor, fontSize: 10),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTime(timestamp),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '-';
    try {
      final time = DateTime.parse(timestamp).toLocal();
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '-';
    }
  }
}
