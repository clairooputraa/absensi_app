import 'package:absensi_app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../services/face_recognition_service.dart';
import '../providers/user_provider.dart';
import 'dart:io';

class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;
  bool _isProcessing = false;
  String _status = 'Posisikan wajah Anda di depan kamera';
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Gunakan kamera depan
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
      }
    } catch (e) {
      _status = 'Error: $e';
    }
  }

  Future<void> _registerFace() async {
    if (!_isCameraReady || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _status = 'Mengambil foto...';
    });

    try {
      final XFile picture = await _cameraController!.takePicture();
      final File imageFile = File(picture.path);

      final faceService = FaceRecognitionService();
      final result = await faceService.detectFace(imageFile);

      if (result.success && result.faceCount == 1) {
        setState(() {
          _status = 'Wajah terdeteksi, menyimpan data...';
        });

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final savedPath = await faceService.saveFaceEmbedding(
            imageFile, userProvider.currentUser!.id);

        faceService.dispose();

        if (savedPath != null) {
          setState(() {
            _isSuccess = true;
            _status = '✅ Registrasi wajah berhasil!';
            _isProcessing = false;
          });

          // Kembali ke halaman sebelumnya setelah 1.5 detik
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.pop(context, true);
            }
          });
        } else {
          setState(() {
            _status = '❌ Gagal menyimpan data wajah, coba lagi';
            _isProcessing = false;
          });
        }
      } else if (result.success && result.faceCount > 1) {
        setState(() {
          _status =
              '❌ Terdeteksi ${result.faceCount} wajah. Hanya satu wajah yang diperbolehkan.';
          _isProcessing = false;
        });
      } else {
        setState(() {
          _status =
              '❌ Wajah tidak terdeteksi. Pastikan wajah Anda terlihat jelas.';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Registrasi Wajah'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Column(
        children: [
          // Preview Kamera
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _isCameraReady
                    ? CameraPreview(_cameraController!)
                    : Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
              ),
            ),
          ),

          // Status Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isSuccess
                    ? Colors.green
                    : (_isProcessing
                        ? Colors.orange
                        : Colors.blue.withOpacity(0.3)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isSuccess
                      ? Icons.check_circle
                      : (_isProcessing ? Icons.hourglass_empty : Icons.face),
                  color: _isSuccess
                      ? Colors.green
                      : (_isProcessing ? Colors.orange : Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _status,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontWeight:
                          _isSuccess ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Informasi Panduan
          if (!_isSuccess && !_isProcessing)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pastikan wajah terlihat jelas dan pencahayaan cukup',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),

          // Tombol Registrasi
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _registerFace,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.camera_alt),
                label: Text(
                  _isProcessing ? 'Memproses...' : 'Ambil Foto & Registrasi',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSuccess ? Colors.green : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
