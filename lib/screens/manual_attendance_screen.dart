// lib/screens/manual_attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/attendance_provider.dart';
import '../helpers/sound_helper.dart';

class ManualAttendanceScreen extends StatefulWidget {
  const ManualAttendanceScreen({super.key});

  @override
  State<ManualAttendanceScreen> createState() => _ManualAttendanceScreenState();
}

class _ManualAttendanceScreenState extends State<ManualAttendanceScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedUserId;
  String _selectedStatus = 'Hadir';
  String _selectedMethod = 'Manual';
  bool _isLoading = false;

  List<Map<String, dynamic>> _users = [];
  String _searchQuery = '';

  final List<String> _statuses = ['Hadir', 'Izin', 'Sakit', 'Alpha'];
  final List<String> _methods = [
    'Manual',
    'Face',
    'RFID',
    'Selfie',
    'Fingerprint',
    'GPS'
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    await attendanceProvider.loadAllUsers();
    setState(() {
      _users = List.from(attendanceProvider.allUsers);
    });
  }

  Future<void> _submitAttendance() async {
    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih user terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    final selectedUser = _users.firstWhere((u) => u['id'] == _selectedUserId);

    final success = await attendanceProvider.markAttendance(
      userId: _selectedUserId!,
      method: _selectedMethod,
      status: _selectedStatus,
      timestamp: DateTime.now(),
    );

    setState(() => _isLoading = false);

    if (success) {
      await SoundHelper.playSuccess();
      _showSuccessDialog(selectedUser['name'] ?? 'User');
    } else {
      await SoundHelper.playError();
      _showErrorDialog('Gagal melakukan absensi manual');
    }
  }

  void _showSuccessDialog(String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, size: 60, color: Colors.green),
        content: Text('Absensi manual untuk $userName berhasil!'),
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

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      final name = (user['name'] ?? '').toLowerCase();
      final email = (user['email'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Absensi Manual'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Gunakan absensi manual jika user tidak bisa terdeteksi secara otomatis (wajah tidak terbaca, RFID rusak, dll)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Search User
              TextField(
                decoration: InputDecoration(
                  labelText: 'Cari User',
                  hintText: 'Cari berdasarkan nama atau email',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Pilih User
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Pilih User',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                ),
                items: _filteredUsers.map<DropdownMenuItem<String>>((user) {
                  return DropdownMenuItem<String>(
                    value: user['id'],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          user['email'] ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUserId = value;
                  });
                },
                validator: (value) {
                  if (value == null) return 'Pilih user terlebih dahulu';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 🔥 Pilih Metode - Ganti initialValue dengan value
              DropdownButtonFormField<String>(
                value: _selectedMethod,  // 🔥 GANTI initialValue dengan value
                decoration: InputDecoration(
                  labelText: 'Metode Absensi',
                  prefixIcon: const Icon(Icons.qr_code_scanner),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                ),
                items: _methods.map<DropdownMenuItem<String>>((method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Text(method),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMethod = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // 🔥 Pilih Status - Ganti initialValue dengan value
              DropdownButtonFormField<String>(
                value: _selectedStatus,  // 🔥 GANTI initialValue dengan value
                decoration: InputDecoration(
                  labelText: 'Status',
                  prefixIcon: const Icon(Icons.assignment_turned_in),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                ),
                items: _statuses.map<DropdownMenuItem<String>>((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Row(
                      children: [
                        Icon(
                          status == 'Hadir'
                              ? Icons.check_circle
                              : status == 'Izin'
                                  ? Icons.description
                                  : status == 'Sakit'
                                      ? Icons.sick
                                      : Icons.cancel,
                          size: 18,
                          color: status == 'Hadir'
                              ? Colors.green
                              : status == 'Izin'
                                  ? Colors.orange
                                  : status == 'Sakit'
                                      ? Colors.red
                                      : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(status),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),

              const SizedBox(height: 32),

              // Tombol Submit
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitAttendance,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isLoading ? 'Memproses...' : 'Simpan Absensi Manual',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
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
      ),
    );
  }
}