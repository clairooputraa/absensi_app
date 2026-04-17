import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../providers/role_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/user_provider.dart';
import '../services/face_recognition_service.dart';
import 'face_registration_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  bool _faceRegistered = false;
  String _selectedLanguage = 'Bahasa Indonesia';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;

  bool _isLoadingFace = true;

  // 🔥 EDIT MODE
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  // 🔥 Text Controllers untuk edit
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _classController; // untuk siswa
  late TextEditingController _nipController; // untuk petugas

  // Local state untuk pengaturan
  bool _faceEnabled = true;
  bool _rfidEnabled = false;
  bool _selfieEnabled = false;
  bool _fingerprintEnabled = false;
  bool _gpsEnabled = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _animationController.forward();

    _loadSettings();
    _checkFaceRegistration();
    _initControllers();
  }

  // 🔥 Inisialisasi controllers
  void _initControllers() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;

    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _classController = TextEditingController(text: user?.kelas ?? '');
    _nipController = TextEditingController(text: user?.nip ?? '');
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _faceEnabled = prefs.getBool('presensi_wajah') ?? true;
      _rfidEnabled = prefs.getBool('presensi_rfid') ?? false;
      _selfieEnabled = prefs.getBool('presensi_selfie') ?? false;
      _fingerprintEnabled = prefs.getBool('presensi_sidik_jari') ?? false;
      _gpsEnabled = prefs.getBool('presensi_gps') ?? false;
    });

    if (!mounted) return;

    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    attendanceProvider.setFaceEnabled(_faceEnabled);
    attendanceProvider.setRfidEnabled(_rfidEnabled);
    attendanceProvider.setSelfieEnabled(_selfieEnabled);
    attendanceProvider.setFingerprintEnabled(_fingerprintEnabled);
    attendanceProvider.setGpsEnabled(_gpsEnabled);
  }

  Future<void> _checkFaceRegistration() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final faceService = FaceRecognitionService();

    try {
      final faceFile =
          await faceService.loadFaceEmbedding(userProvider.currentUser!.id);
      setState(() {
        _faceRegistered = faceFile != null;
        _isLoadingFace = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFace = false;
      });
    }
    faceService.dispose();
  }

  Future<void> _reRegisterFace() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FaceRegistrationScreen()),
    );

    if (result == true) {
      await _checkFaceRegistration();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wajah berhasil didaftarkan ulang'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // 🔥 METHOD UPDATE METODE AKTIF KE SHAREDPREFERENCES
  Future<void> _updateActiveMethod() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('presensi_wajah', _faceEnabled);
    await prefs.setBool('presensi_rfid', _rfidEnabled);
    await prefs.setBool('presensi_selfie', _selfieEnabled);
    await prefs.setBool('presensi_sidik_jari', _fingerprintEnabled);
    await prefs.setBool('presensi_gps', _gpsEnabled);

    String activeMethod = 'wajah';
    String activeMethodName = 'Pengenalan Wajah';
    String activeMethodIcon = 'face';

    if (_faceEnabled) {
      activeMethod = 'wajah';
      activeMethodName = 'Pengenalan Wajah';
      activeMethodIcon = 'face';
    } else if (_selfieEnabled) {
      activeMethod = 'selfie';
      activeMethodName = 'Presensi Selfie';
      activeMethodIcon = 'camera_alt';
    } else if (_rfidEnabled) {
      activeMethod = 'rfid';
      activeMethodName = 'Kartu RFID';
      activeMethodIcon = 'nfc';
    } else if (_fingerprintEnabled) {
      activeMethod = 'finger';
      activeMethodName = 'Sidik Jari';
      activeMethodIcon = 'fingerprint';
    } else if (_gpsEnabled) {
      activeMethod = 'lokasi';
      activeMethodName = 'GPS';
      activeMethodIcon = 'location_on';
    }

    await prefs.setString('active_absen_method', activeMethod);
    await prefs.setString('active_method_name', activeMethodName);
    await prefs.setString('active_method_icon', activeMethodIcon);
  }

  // 🔥 HANDLE TOGGLE SETTING
  void _onPresensiChanged(String method, bool value) {
    setState(() {
      switch (method) {
        case 'face':
          _faceEnabled = value;
          break;
        case 'rfid':
          _rfidEnabled = value;
          break;
        case 'selfie':
          _selfieEnabled = value;
          break;
        case 'fingerprint':
          _fingerprintEnabled = value;
          break;
        case 'gps':
          _gpsEnabled = value;
          break;
      }
    });

    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    attendanceProvider.setFaceEnabled(_faceEnabled);
    attendanceProvider.setRfidEnabled(_rfidEnabled);
    attendanceProvider.setSelfieEnabled(_selfieEnabled);
    attendanceProvider.setFingerprintEnabled(_fingerprintEnabled);
    attendanceProvider.setGpsEnabled(_gpsEnabled);

    _updateActiveMethod();
  }

  // 🔥 TOGGLE EDIT MODE (hanya untuk admin)
  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  // 🔥 SAVE PROFILE
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    final isPetugas = user?.role == 'Petugas';

    setState(() {
      _isEditing = false;
    });

    try {
      final updateData = {
        'name': _nameController.text,
        'phone_number': _phoneController.text,
        'email': _emailController.text,
      };

      if (isPetugas) {
        updateData['nip'] = _nipController.text;
      } else {
        updateData['class'] = _classController.text;
      }

      await userProvider.updateUser(user!.id, updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profil berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🔥 METHOD UNTUK GANTI FOTO PROFIL (SEMUA USER BISA)
  Future<void> _changeProfilePhoto() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Ganti Foto Profil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Ambil Foto'),
              onTap: () async {
                Navigator.pop(context);
                final image = await userProvider.pickImageFromCamera();
                if (image != null && mounted) {
                  final success = await userProvider.updateProfilePhoto(image);
                  if (!mounted) return;
                  if (success) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Foto profil berhasil diupdate'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Pilih dari Galeri'),
              onTap: () async {
                Navigator.pop(context);
                final image = await userProvider.pickImageFromGallery();
                if (image != null && mounted) {
                  final success = await userProvider.updateProfilePhoto(image);
                  if (!mounted) return;
                  if (success) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Foto profil berhasil diupdate'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
            ),
            if (userProvider.currentUser?.photoUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Hapus Foto'),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await userProvider.deleteProfilePhoto();
                  if (!mounted) return;
                  if (success) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🗑️ Foto profil berhasil dihapus'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // 🔥 WIDGET AVATAR DENGAN FOTO PROFIL
  Widget _buildProfileAvatar() {
    final userProvider = Provider.of<UserProvider>(context);
    final photoUrl = userProvider.currentUser?.photoUrl;
    final hasPhoto = photoUrl != null && File(photoUrl).existsSync();

    return GestureDetector(
      onTap: _changeProfilePhoto,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 65,
              backgroundColor: Colors.white,
              backgroundImage: hasPhoto ? FileImage(File(photoUrl)) : null,
              child: !hasPhoto
                  ? const Icon(Icons.person, size: 65, color: Color(0xFF2196F3))
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child:
                  const Icon(Icons.camera_alt, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scaleController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _classController.dispose();
    _nipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final roleProvider = Provider.of<RoleProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final isPetugas = roleProvider.userRole == 'Petugas';
    final user = userProvider.currentUser;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A2A) : const Color(0xFFF0F4FF),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2196F3),
                        Color(0xFF1565C0),
                        Color(0xFF0D47A1)
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        ScaleTransition(
                          scale: _scaleController,
                          child: _buildProfileAvatar(), // 🔥 GANTI DENGAN INI
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.name ?? 'Petugas',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user?.email ?? 'petugas@gmail.com',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.white24, Colors.white12],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.school, size: 16, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                isPetugas ? 'SMKN 8 Malang' : 'Kelas XII RPL 1',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                        color: Colors.white),
                    onPressed: () => themeProvider.toggleTheme(),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Info Card Premium dengan Tombol Edit
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, double value, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: Container(
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
                                    : Colors.blue.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    const Icon(Icons.account_circle,
                                        color: Color(0xFF2196F3), size: 28),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'INFORMASI AKUN',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (isPetugas)
                                      IconButton(
                                        icon: Icon(
                                          _isEditing ? Icons.close : Icons.edit,
                                          size: 20,
                                          color: Colors.blue,
                                        ),
                                        onPressed: _toggleEditMode,
                                      ),
                                  ],
                                ),
                              ),
                              _buildInfoRowEditable(
                                Icons.person_outline,
                                'Nama Lengkap',
                                user?.name ?? 'Petugas',
                                isDark,
                                controller: _nameController,
                                isEditing: _isEditing && isPetugas,
                              ),
                              const Divider(
                                  height: 0, indent: 20, endIndent: 20),
                              _buildInfoRowEditable(
                                Icons.phone_outlined,
                                'Nomor Telepon',
                                user?.phoneNumber ?? 'Belum diisi',
                                isDark,
                                controller: _phoneController,
                                isEditing: _isEditing && isPetugas,
                              ),
                              const Divider(
                                  height: 0, indent: 20, endIndent: 20),
                              _buildInfoRowEditable(
                                Icons.email_outlined,
                                'Email',
                                user?.email ?? 'petugas@gmail.com',
                                isDark,
                                controller: _emailController,
                                isEditing: _isEditing && isPetugas,
                              ),
                              const Divider(
                                  height: 0, indent: 20, endIndent: 20),
                              if (isPetugas)
                                _buildInfoRowEditable(
                                  Icons.badge_outlined,
                                  'NIP',
                                  user?.nip ?? 'Belum diisi',
                                  isDark,
                                  controller: _nipController,
                                  isEditing: _isEditing && isPetugas,
                                )
                              else
                                _buildInfoRowEditable(
                                  Icons.class_outlined,
                                  'Kelas',
                                  user?.kelas ?? 'Belum diisi',
                                  isDark,
                                  controller: _classController,
                                  isEditing: _isEditing && isPetugas,
                                ),
                              const Divider(
                                  height: 0, indent: 20, endIndent: 20),
                              _buildInfoRow(
                                Icons.work_outline,
                                'Jabatan',
                                isPetugas ? 'Petugas' : 'Siswa',
                                isDark,
                              ),
                              const SizedBox(height: 20),
                              if (_isEditing && isPetugas)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  child: ElevatedButton.icon(
                                    onPressed: _saveProfile,
                                    icon: const Icon(Icons.save),
                                    label: const Text('Simpan Perubahan'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      minimumSize:
                                          const Size(double.infinity, 45),
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

                      const SizedBox(height: 16),

                      // Face Recognition Card Premium
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 600),
                        builder: (context, double value, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: Container(
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
                                    : Colors.blue.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.face,
                                      color: Color(0xFF2196F3), size: 28),
                                  SizedBox(width: 12),
                                  Text(
                                    'Pengenalan Wajah',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_isLoadingFace)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: _faceRegistered
                                              ? [
                                                  Colors.green,
                                                  Colors.green.shade700
                                                ]
                                              : [
                                                  Colors.red,
                                                  Colors.red.shade700
                                                ],
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (_faceRegistered
                                                    ? Colors.green
                                                    : Colors.red)
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle,
                                              size: 16, color: Colors.white),
                                          const SizedBox(width: 8),
                                          Text(
                                            _faceRegistered
                                                ? 'Sudah terdaftar'
                                                : 'Belum terdaftar',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: _faceEnabled
                                              ? [Colors.blue, const Color(0xFF1565C0)]
                                              : [
                                                  Colors.grey,
                                                  Colors.grey.shade700
                                                ],
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: [
                                          if (_faceEnabled)
                                            BoxShadow(
                                              color:
                                                  Colors.blue.withValues(alpha: 0.3),
                                              blurRadius: 8,
                                            ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                              _faceEnabled
                                                  ? Icons.check_circle
                                                  : Icons.power_off,
                                              size: 16,
                                              color: Colors.white),
                                          const SizedBox(width: 8),
                                          Text(
                                            _faceEnabled ? 'Aktif' : 'Nonaktif',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _reRegisterFace,
                                  icon: const Icon(Icons.refresh, size: 20),
                                  label: const Text('Daftar Ulang Wajah',
                                      style: TextStyle(fontSize: 14)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: Color(0xFF2196F3), width: 2),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Attendance Settings (Hanya untuk Petugas)
                      if (isPetugas) ...[
                        const SizedBox(height: 16),
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 700),
                          builder: (context, double value, child) {
                            return Transform.translate(
                              offset: Offset(0, 30 * (1 - value)),
                              child: Opacity(opacity: value, child: child),
                            );
                          },
                          child: Container(
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
                                      : Colors.blue.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ExpansionTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF2196F3),
                                      Color(0xFF1565C0)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.settings,
                                    size: 24, color: Colors.white),
                              ),
                              title: const Text(
                                'Pengaturan Presensi',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text(
                                  'Atur metode absensi untuk semua user'),
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Text(
                                    'Pengaturan ini akan mempengaruhi semua user',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                                const Divider(),
                                _buildPresensiItem(
                                  icon: Icons.face,
                                  title: 'Pengenalan Wajah',
                                  subtitle: 'Scan wajah untuk presensi',
                                  color: Colors.orange,
                                  value: _faceEnabled,
                                  onChanged: (val) =>
                                      _onPresensiChanged('face', val),
                                  isDark: isDark,
                                ),
                                const Divider(height: 0),
                                _buildPresensiItem(
                                  icon: Icons.nfc,
                                  title: 'Kartu RFID',
                                  subtitle: 'Tempel kartu RFID pada scanner',
                                  color: Colors.purple,
                                  value: _rfidEnabled,
                                  onChanged: (val) =>
                                      _onPresensiChanged('rfid', val),
                                  isDark: isDark,
                                ),
                                const Divider(height: 0),
                                _buildPresensiItem(
                                  icon: Icons.camera_alt,
                                  title: 'Presensi Selfie',
                                  subtitle: 'Ambil foto selfie untuk presensi',
                                  color: Colors.blue,
                                  value: _selfieEnabled,
                                  onChanged: (val) =>
                                      _onPresensiChanged('selfie', val),
                                  isDark: isDark,
                                ),
                                const Divider(height: 0),
                                _buildPresensiItem(
                                  icon: Icons.fingerprint,
                                  title: 'Sidik Jari',
                                  subtitle: 'Scan sidik jari untuk presensi',
                                  color: Colors.green,
                                  value: _fingerprintEnabled,
                                  onChanged: (val) =>
                                      _onPresensiChanged('fingerprint', val),
                                  isDark: isDark,
                                ),
                                const Divider(height: 0),
                                _buildPresensiItem(
                                  icon: Icons.location_on,
                                  title: 'GPS',
                                  subtitle: 'Lokasi untuk presensi',
                                  color: Colors.teal,
                                  value: _gpsEnabled,
                                  onChanged: (val) =>
                                      _onPresensiChanged('gps', val),
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Language Settings
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, double value, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: Container(
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
                                    : Colors.blue.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ExpansionTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2196F3),
                                    Color(0xFF1565C0)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.language,
                                  size: 24, color: Colors.white),
                            ),
                            title: const Text(
                              'Pengaturan Bahasa',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            children: [
                              RadioListTile(
                                title: const Text('Bahasa Indonesia',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500)),
                                subtitle: const Text('Indonesian'),
                                value: 'Bahasa Indonesia',
                                onChanged: (value) => setState(
                                    () => _selectedLanguage = value.toString()),
                                activeColor: const Color(0xFF2196F3),
                              ),
                              RadioListTile(
                                title: const Text('English',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500)),
                                subtitle: const Text('International'),
                                value: 'English',
                                onChanged: (value) => setState(
                                    () => _selectedLanguage = value.toString()),
                                activeColor: const Color(0xFF2196F3),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Logout Button Premium
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 900),
                        builder: (context, double value, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showLogoutDialog(),
                            icon: const Icon(Icons.logout_outlined, size: 22),
                            label: const Text(
                              'Logout',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 BUILD INFO ROW (READ ONLY)
  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF2196F3)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 BUILD INFO ROW (EDITABLE)
  Widget _buildInfoRowEditable(
    IconData icon,
    String label,
    String value,
    bool isDark, {
    TextEditingController? controller,
    bool isEditing = false,
  }) {
    if (isEditing && controller != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF2196F3)),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: controller,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '$label tidak boleh kosong';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      );
    }

    return _buildInfoRow(icon, label, value, isDark);
  }

  Widget _buildPresensiItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool value,
    required Function(bool) onChanged,
    required bool isDark,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: TextStyle(
              fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[500])),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFF2196F3),
        activeTrackColor: const Color(0xFF2196F3).withValues(alpha: 0.3),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Logout',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
