// lib/screens/face_attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/user_provider.dart';
import '../services/face_recognition_service.dart';
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
  String _status = 'Posisikan wajah Anda di depan kamera';
  File? _capturedImage;
  final FaceRecognitionService _faceService = FaceRecognitionService();
  bool _hasRegisteredFace = false;

  // 🔥 Untuk face detection realtime
  Timer? _detectionTimer;
  bool _isFaceDetected = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _checkRegisteredFace();
  }

  Future<void> _checkRegisteredFace() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final faceFile =
        await _faceService.loadFaceEmbedding(userProvider.currentUser!.id);
    setState(() {
      _hasRegisteredFace = faceFile != null;
      if (!_hasRegisteredFace) {
        _status =
            'Anda belum mendaftarkan wajah. Silakan registrasi terlebih dahulu.';
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
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();

      setState(() {
        _isCameraReady = true;
      });

      // 🔥 LANGSUNG MULAI DETEKSI WAJAH (tanpa syarat)
      _startFaceDetection();
    }
  }

  // 🔥 START FACE DETECTION REALTIME
  void _startFaceDetection() {
    _detectionTimer =
        Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_isCameraReady && !_isProcessing) {
        _detectFaceRealtime();
      }
    });
  }

  // 🔥 DETEKSI WAJAH REALTIME (DIPERBAIKI dengan kurung kurawal)
  Future<void> _detectFaceRealtime() async {
    try {
      // 🔥 PERBAIKAN: Tambahkan kurung kurawal {}
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        return;
      }

      // Ambil frame dari kamera
      final XFile picture = await _cameraController!.takePicture();
      final File imageFile = File(picture.path);

      final result = await _faceService.detectFace(imageFile);

      if (mounted) {
        setState(() {
          _isFaceDetected = result.success && result.faceCount == 1;

          if (_isFaceDetected) {
            _status = '🎯 Wajah terdeteksi!';
          } else {
            _status = '📷 Arahkan wajah ke dalam kotak';
          }
        });

        // 🔥 AUTO ABSEN (hanya jika sudah registrasi dan wajah terdeteksi)
        if (widget.autoCapture &&
            _isFaceDetected &&
            !_isProcessing &&
            _hasRegisteredFace) {
          _detectionTimer?.cancel();
          await _takeAttendance(imageFile);
        }
      }

      // Hapus file temporary
      await imageFile.delete();
    } catch (e) {
      // Jangan print error setiap frame
    }
  }

  Future<void> _registerFace() async {
    if (!_isCameraReady || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _status = 'Mengambil foto wajah...';
    });

    try {
      final XFile picture = await _cameraController!.takePicture();
      final File imageFile = File(picture.path);

      final result = await _faceService.detectFace(imageFile);

      if (result.success && result.faceCount == 1) {
        _status = 'Wajah terdeteksi, menyimpan data...';

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final savedPath = await _faceService.saveFaceEmbedding(
            imageFile, userProvider.currentUser!.id);

        if (savedPath != null) {
          setState(() {
            _hasRegisteredFace = true;
            _status = '✅ Registrasi wajah berhasil!';
            _capturedImage = imageFile;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Registrasi wajah berhasil!'),
                backgroundColor: Colors.green),
          );
        } else {
          _status = '❌ Gagal menyimpan data wajah';
        }
      } else if (result.success && result.faceCount > 1) {
        _status =
            '❌ Terdeteksi ${result.faceCount} wajah. Hanya satu wajah yang diperbolehkan.';
      } else {
        _status = '❌ Wajah tidak terdeteksi. Coba lagi.';
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
    if (!_isCameraReady || _isProcessing) return;
    if (!_hasRegisteredFace) {
      _status = 'Silakan registrasi wajah terlebih dahulu';
      return;
    }

    setState(() {
      _isProcessing = true;
      _status = 'Memproses absensi...';
    });

    try {
      File imageFile = preCapturedImage ??
          File((await _cameraController!.takePicture()).path);

      final result = await _faceService.detectFace(imageFile);

      if (result.success && result.faceCount == 1) {
        _status = 'Wajah terdeteksi, verifikasi...';

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
              _showSuccessDialog();
            } else {
              _status = '❌ Absen gagal, coba lagi';
            }
          } else {
            _status = '❌ Wajah tidak cocok dengan data registrasi';
          }
        }
      } else if (result.success && result.faceCount > 1) {
        _status =
            '❌ Terdeteksi ${result.faceCount} wajah. Hanya satu wajah yang diperbolehkan.';
      } else {
        _status = '❌ Wajah tidak terdeteksi. Coba lagi.';
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
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
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
              child: const Text(
                'Auto Mode',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
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
                  // 🔥 KOTAK DETEKSI WAJAH (SELALU TAMPIL SEBAGAI PANDUAN)
                  if (widget.showDetectionBox && _isCameraReady)
                    _buildFaceDetectionBox(),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
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
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isProcessing || widget.autoCapture)
                        ? null
                        : _takeAttendance,
                    icon: const Icon(Icons.check_circle),
                    label: Text(widget.autoCapture ? 'Auto Mode ON' : 'Absen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          widget.autoCapture ? Colors.green : Colors.blue,
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
        ],
      ),
    );
  }

  // 🔥 WIDGET KOTAK DETEKSI (BERUBAH WARNA SAAT WAJAH TERDETEKSI)
  Widget _buildFaceDetectionBox() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(
            color:
                _isFaceDetected ? Colors.green : Colors.white.withOpacity(0.5),
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
            margin: const EdgeInsets.only(top: 12),
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
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
