import 'package:absensi_app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/user_provider.dart';
//import '../helpers/sound_helper.dart';
import 'dart:io';
import 'dart:async';

class CameraSelfieScreen extends StatefulWidget {
  const CameraSelfieScreen({super.key});

  @override
  State<CameraSelfieScreen> createState() => _CameraSelfieScreenState();
}

class _CameraSelfieScreenState extends State<CameraSelfieScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;
  bool _isProcessing = false;
  bool _isFrontCamera = true;
  File? _selfieImage;
  int _countdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      final cameraIndex = _isFrontCamera
          ? _cameras!.indexWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front)
          : _cameras!.indexWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back);

      final selectedCamera =
          cameraIndex != -1 ? _cameras![cameraIndex] : _cameras![0];

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      setState(() {
        _isCameraReady = true;
      });
    }
  }

  Future<void> _switchCamera() async {
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
    await _initCamera();
  }

  Future<void> _takeSelfie() async {
    if (!_isCameraReady || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile picture = await _cameraController!.takePicture();
      _selfieImage = File(picture.path);

      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final success = await attendanceProvider.markAttendance(
        userId: userProvider.currentUser!.id,
        method: 'Selfie',
        status: 'Hadir',
        timestamp: DateTime.now(),
        photoUrl: picture.path,
      );

      if (success) {
        // await SoundHelper.playSuccess();
        _showSuccessDialog();
      } else {
        // await SoundHelper.playError();
        _showErrorDialog('Absensi gagal, coba lagi');
      }
    } catch (e) {
      // await SoundHelper.playError();
      _showErrorDialog('Error: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _startCountdown() {
    if (_isProcessing) return;

    setState(() {
      _countdown = 3;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          _countdownTimer?.cancel();
          _countdown = 0;
          _takeSelfie();
        }
      });
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, size: 60, color: Colors.green),
        content: const Text('Selfie Berhasil!\nAbsensi tercatat'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
  void dispose() {
    _cameraController?.dispose();
    _countdownTimer?.cancel();
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
        title: const Text('Presensi Selfie'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.switch_camera),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera Preview
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _isCameraReady
                    ? CameraPreview(_cameraController!)
                    : Container(
                        color: Colors.grey[900],
                        child:
                            const Center(child: CircularProgressIndicator())),
              ),
            ),
          ),

          // Countdown
          if (_countdown > 0)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                '$_countdown',
                style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange),
              ),
            ),

          // Info
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
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Posisikan wajah di tengah frame',
                    style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ],
            ),
          ),

          // Capture Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _startCountdown,
              icon: Icon(
                  _isProcessing ? Icons.hourglass_empty : Icons.camera_alt,
                  size: 32),
              label: Text(
                _isProcessing ? 'Memproses...' : 'Ambil Selfie & Absen',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          // Preview
          if (_selfieImage != null)
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
                    child: Image.file(_selfieImage!,
                        height: 60, width: 60, fit: BoxFit.cover),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
