// lib/screens/face_attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/user_provider.dart';
import '../services/face_recognition_service.dart';
import '../helpers/sound_helper.dart';
import 'dart:io';
import 'dart:async';

class FaceAttendanceScreen extends StatefulWidget {
  final bool autoCapture;
  final bool showDetectionBox;

  const FaceAttendanceScreen({
    super.key,
    this.autoCapture = true,
    this.showDetectionBox = true,
  });

  @override
  State<FaceAttendanceScreen> createState() => _FaceAttendanceScreenState();
}

class _FaceAttendanceScreenState extends State<FaceAttendanceScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;
  bool _isProcessing = false;
  bool _isSuccess = false;
  String _status = '📷 Hadapkan wajah ke kamera';
  File? _capturedImage;
  final FaceRecognitionService _faceService = FaceRecognitionService();
  bool _hasRegisteredFace = false;

  // 🔥 Untuk face detection realtime
  Timer? _detectionTimer;
  bool _isFaceDetected = false;

  // 🔥 Untuk tripod mode (absen cepat)
  DateTime? _lastAttendanceTime;
  static const Duration _cooldown = Duration(seconds: 3);

  // 🔥 UNTUK RECENT ATTENDANCE LIST
  Timer? _recentListTimer;
  List<Map<String, dynamic>> _recentAttendance = [];

  @override
  void initState() {
    super.initState();
    _initCamera();
    _checkRegisteredFace();
    _loadRecentAttendance();

    // 🔥 TIMER UNTUK UPDATE RECENT LIST SETIAP 2 DETIK
    _recentListTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isCameraReady) {
        _loadRecentAttendance();
      }
    });
  }

  // 🔥 LOAD RECENT ATTENDANCE
  Future<void> _loadRecentAttendance() async {
    try {
      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);
      final response = await attendanceProvider.getAttendanceHistory(limit: 10);

      if (mounted) {
        setState(() {
          _recentAttendance = response;
        });
      }
    } catch (e) {
      print('Error loading recent: $e');
    }
  }

  Future<void> _checkRegisteredFace() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final faceFile =
        await _faceService.loadFaceEmbedding(userProvider.currentUser!.id);
    setState(() {
      _hasRegisteredFace = faceFile != null;
      if (!_hasRegisteredFace) {
        _status =
            '⚠️ Anda belum mendaftarkan wajah. Silakan registrasi terlebih dahulu.';
      }
    });
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras![0],
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
      );
      await _cameraController!.initialize();

      setState(() {
        _isCameraReady = true;
      });

      _startFastFaceDetection();
    }
  }

  void _startFastFaceDetection() {
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isCameraReady && !_isProcessing && !_isSuccess) {
        _fastDetectAndAbsen();
      }
    });
  }

  Future<void> _fastDetectAndAbsen() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        _isProcessing = false;
        return;
      }

      final XFile picture = await _cameraController!.takePicture();
      final File imageFile = File(picture.path);

      final result = await _faceService.detectFace(imageFile);

      if (mounted) {
        setState(() {
          _isFaceDetected = result.success && result.faceCount == 1;

          if (_isFaceDetected) {
            _status = '🎯 Wajah terdeteksi! Memproses...';
          }
        });

        if (widget.autoCapture &&
            _isFaceDetected &&
            !_isSuccess &&
            _hasRegisteredFace) {
          if (_lastAttendanceTime != null &&
              DateTime.now().difference(_lastAttendanceTime!) < _cooldown) {
            _status = '⏳ Tunggu sebentar...';
            _isProcessing = false;
            return;
          }

          _isSuccess = true;
          _detectionTimer?.cancel();

          await _takeAttendance(imageFile);

          _lastAttendanceTime = DateTime.now();

          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            setState(() {
              _isSuccess = false;
              _isFaceDetected = false;
              _status = '📷 Siap untuk siswa berikutnya';
            });
            _startFastFaceDetection();
          }
        }
      }

      await imageFile.delete();
      _isProcessing = false;
    } catch (e) {
      _isProcessing = false;
    }
  }

  Future<void> _registerFace() async {
    if (!_isCameraReady || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _status = '📸 Mengambil foto wajah...';
    });

    try {
      final XFile picture = await _cameraController!.takePicture();
      final File imageFile = File(picture.path);

      final result = await _faceService.detectFace(imageFile);

      if (result.success && result.faceCount == 1) {
        _status = '💾 Wajah terdeteksi, menyimpan data...';

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final savedPath = await _faceService.saveFaceEmbedding(
            imageFile, userProvider.currentUser!.id);

        if (savedPath != null) {
          setState(() {
            _hasRegisteredFace = true;
            _status = '✅ Registrasi wajah berhasil!';
            _capturedImage = imageFile;
          });
          await SoundHelper.playSuccess();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Registrasi wajah berhasil!'),
                backgroundColor: Colors.green),
          );
        } else {
          _status = '❌ Gagal menyimpan data wajah';
          await SoundHelper.playError();
        }
      } else if (result.success && result.faceCount > 1) {
        _status =
            '❌ Terdeteksi ${result.faceCount} wajah. Hanya satu yang diperbolehkan.';
        await SoundHelper.playError();
      } else {
        _status = '❌ Wajah tidak terdeteksi. Coba lagi.';
        await SoundHelper.playError();
      }
    } catch (e) {
      _status = 'Error: $e';
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _takeAttendance([File? preCapturedImage]) async {
    if (!_isCameraReady) return;
    if (!_hasRegisteredFace) {
      _status = '⚠️ Silakan registrasi wajah terlebih dahulu';
      return;
    }

    setState(() {
      _isProcessing = true;
      _status = '🔄 Memproses absensi...';
    });

    try {
      File imageFile = preCapturedImage ??
          File((await _cameraController!.takePicture()).path);

      final result = await _faceService.detectFace(imageFile);

      if (result.success && result.faceCount == 1) {
        _status = '🔍 Verifikasi wajah...';

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final registeredFace =
            await _faceService.loadFaceEmbedding(userProvider.currentUser!.id);

        if (registeredFace != null) {
          final similarity =
              await _faceService.verifyFace(registeredFace, imageFile);

          if (similarity > 0.7) {
            final attendanceProvider =
                Provider.of<AttendanceProvider>(context, listen: false);
            final success = await attendanceProvider.markAttendance(
              userId: userProvider.currentUser!.id,
              method: 'Face',
              status: 'Hadir',
              timestamp: DateTime.now(),
              photoUrl: imageFile.path,
            );

            if (success) {
              _status = '✅ Absen berhasil!';
              _capturedImage = imageFile;
              await SoundHelper.playSuccess();
              await _loadRecentAttendance(); // 🔥 RELOAD RECENT LIST
              _showSuccessDialog();
            } else {
              _status = '❌ Absen gagal, coba lagi';
              await SoundHelper.playError();
            }
          } else {
            _status = '❌ Wajah tidak cocok dengan data registrasi';
            await SoundHelper.playError();
          }
        }
      } else if (result.success && result.faceCount > 1) {
        _status =
            '❌ Terdeteksi ${result.faceCount} wajah. Hanya satu yang diperbolehkan.';
        await SoundHelper.playError();
      } else {
        _status = '❌ Wajah tidak terdeteksi. Coba lagi.';
        await SoundHelper.playError();
      }
    } catch (e) {
      _status = 'Error: $e';
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
        title: const Icon(Icons.check_circle, size: 60, color: Colors.green),
        content: const Text('Absensi Wajah Berhasil!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // 🔥 WIDGET RECENT ATTENDANCE LIST
  Widget _buildRecentAttendanceList() {
    if (_recentAttendance.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.history, size: 32, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Belum ada yang absen hari ini',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '🕐 Siswa yang baru absen:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount:
              _recentAttendance.length > 5 ? 5 : _recentAttendance.length,
          itemBuilder: (context, index) {
            final item = _recentAttendance[index];
            final time = DateTime.parse(item['timestamp']);
            final timeStr =
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.withOpacity(0.2),
                child: const Icon(Icons.check_circle,
                    color: Colors.green, size: 18),
              ),
              title: Text(
                item['user_name'] ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                '${item['method']} • $timeStr',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'HADIR',
                  style: TextStyle(color: Colors.green, fontSize: 10),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _recentListTimer?.cancel();
    _cameraController?.dispose();
    _faceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Absensi Wajah'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.autoCapture)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.speed, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'TRIPOD MODE',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 🔥 STATUS BESAR UNTUK TRIPOD
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: _isSuccess
                ? Colors.green
                : (_isFaceDetected ? Colors.blue : Colors.grey),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSuccess
                        ? Icons.check_circle
                        : (_isFaceDetected ? Icons.face : Icons.camera_front),
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isSuccess
                        ? 'ABSEN BERHASIL!'
                        : (_isFaceDetected
                            ? 'WAJAH TERDETEKSI'
                            : 'HADAPKAN WAJAH'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 20)
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: _isCameraReady
                        ? CameraPreview(_cameraController!)
                        : Container(
                            color: Colors.grey[900],
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),
                  ),
                  if (widget.showDetectionBox && _isCameraReady)
                    _buildFaceDetectionBox(),
                ],
              ),
            ),
          ),

          // 🔥 STATUS TEXT
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isFaceDetected
                    ? Colors.green
                    : Colors.blue.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isProcessing
                      ? Icons.hourglass_empty
                      : (_isFaceDetected ? Icons.face : Icons.camera_front),
                  color: _isProcessing
                      ? Colors.orange
                      : (_isFaceDetected ? Colors.green : Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _status,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontWeight:
                          _isFaceDetected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🔥 TOMBOL REGISTRASI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _registerFace,
                    icon: const Icon(Icons.app_registration),
                    label: const Text('Registrasi Wajah'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🔥 RECENT ATTENDANCE LIST (TAMBAHKAN DI SINI)
          if (_hasRegisteredFace)
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildRecentAttendanceList(),
            ),

          if (_capturedImage != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text('Foto Terakhir',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_capturedImage!,
                        height: 60, width: 60, fit: BoxFit.cover),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 🔥 WIDGET KOTAK DETEKSI
  Widget _buildFaceDetectionBox() {
    return Center(
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          border: Border.all(
            color: _isFaceDetected
                ? (_isSuccess ? Colors.green : Colors.green)
                : Colors.white.withOpacity(0.5),
            width: _isFaceDetected ? 4 : 2,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: _isFaceDetected
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ]
              : [],
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: -12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _isFaceDetected ? Colors.green : Colors.white54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isFaceDetected
                  ? '✓ WAJAH TERDETEKSI'
                  : '◯ TEMPATKAN WAJAH DI SINI',
              style: TextStyle(
                color: _isFaceDetected ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
