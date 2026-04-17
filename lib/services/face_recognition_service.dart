import 'dart:io';
import 'dart:ui'; //  TAMBAHKAN IMPORT INI untuk Rect
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';

class FaceRecognitionService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: true,
    ),
  );

  // 🔥 Cache untuk menyimpan embedding sementara
  final Map<String, List<double>> _embeddingCache = {};

  Future<FaceDetectionResult> detectFace(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      return FaceDetectionResult(
        success: faces.isNotEmpty,
        faceCount: faces.length,
        faces: faces,
      );
    } catch (e) {
      print('Face detection error: $e');
      return FaceDetectionResult(success: false, faceCount: 0, faces: []);
    }
  }

  // 🔥 TAMBAHKAN: Deteksi multiple faces dalam satu frame
  Future<MultiFaceDetectionResult> detectMultipleFaces(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      final List<Map<String, dynamic>> faceData = [];
      for (var face in faces) {
        faceData.add({
          'face': face,
          'boundingBox': face.boundingBox,
          'trackingId': face.trackingId,
        });
      }

      return MultiFaceDetectionResult(
        success: faces.isNotEmpty,
        faceCount: faces.length,
        faces: faces,
        faceData: faceData,
      );
    } catch (e) {
      print('Multi-face detection error: $e');
      return MultiFaceDetectionResult(
        success: false,
        faceCount: 0,
        faces: [],
        faceData: [],
      );
    }
  }

  // 🔥 TAMBAHKAN: Identifikasi wajah dari database
  Future<String?> identifyFace(File faceImage) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final faceDir = Directory('${directory.path}/faces');

      if (!await faceDir.exists()) {
        return null;
      }

      final List<FileSystemEntity> files = await faceDir.list().toList();

      for (var file in files) {
        if (file is File && file.path.endsWith('.jpg')) {
          // Ekstrak userId dari nama file
          final fileName = file.path.split('\\').last;
          final userId = fileName.replaceAll('_face.jpg', '');

          // Verifikasi wajah
          final similarity = await verifyFace(file, faceImage);
          if (similarity > 0.7) {
            return userId;
          }
        }
      }
      return null;
    } catch (e) {
      print('Identify face error: $e');
      return null;
    }
  }

  // 🔥 TAMBAHKAN: Identifikasi multiple faces dalam satu frame
  Future<List<Map<String, dynamic>>> identifyMultipleFaces(
      File imageFile) async {
    try {
      final multiResult = await detectMultipleFaces(imageFile);
      if (!multiResult.success) return [];

      final List<Map<String, dynamic>> results = [];

      for (var faceData in multiResult.faceData) {
        // Extract face region dari gambar
        final faceImage =
            await _extractFaceRegion(imageFile, faceData['boundingBox']);
        if (faceImage != null) {
          final userId = await identifyFace(faceImage);
          if (userId != null) {
            results.add({
              'userId': userId,
              'boundingBox': faceData['boundingBox'],
              'trackingId': faceData['trackingId'],
            });
          }
        }
      }

      return results;
    } catch (e) {
      print('Identify multiple faces error: $e');
      return [];
    }
  }

  // 🔥 TAMBAHKAN: Extract face region dari gambar
  Future<File?> _extractFaceRegion(File imageFile, Rect boundingBox) async {
    try {
      // TODO: Implement crop image berdasarkan bounding box
      // Untuk sementara return image asli
      return imageFile;
    } catch (e) {
      print('Extract face region error: $e');
      return null;
    }
  }

  // 🔥 TAMBAHKAN: Cek apakah wajah sudah terdaftar
  Future<bool> isFaceRegistered(String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final facePath = '${directory.path}/faces/${userId}_face.jpg';
      final faceFile = File(facePath);
      return await faceFile.exists();
    } catch (e) {
      print('Check face registered error: $e');
      return false;
    }
  }

  // 🔥 TAMBAHKAN: Hapus data wajah
  Future<bool> deleteFaceData(String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final facePath = '${directory.path}/faces/${userId}_face.jpg';
      final faceFile = File(facePath);

      if (await faceFile.exists()) {
        await faceFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Delete face error: $e');
      return false;
    }
  }

  // 🔥 TAMBAHKAN: Get all registered users
  Future<List<String>> getAllRegisteredUsers() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final faceDir = Directory('${directory.path}/faces');

      if (!await faceDir.exists()) {
        return [];
      }

      final List<String> userIds = [];
      final List<FileSystemEntity> files = await faceDir.list().toList();

      for (var file in files) {
        if (file is File && file.path.endsWith('.jpg')) {
          final fileName = file.path.split('\\').last;
          final userId = fileName.replaceAll('_face.jpg', '');
          userIds.add(userId);
        }
      }

      return userIds;
    } catch (e) {
      print('Get all registered users error: $e');
      return [];
    }
  }

  Future<double> verifyFace(File face1, File face2) async {
    // TODO: Implementasi face comparison dengan ML model
    // Untuk sementara return similarity tinggi untuk testing
    await Future.delayed(const Duration(milliseconds: 100));
    return 0.85;
  }

  Future<String?> saveFaceEmbedding(File faceImage, String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final faceDir = Directory('${directory.path}/faces');
      if (!await faceDir.exists()) {
        await faceDir.create(recursive: true);
      }

      final fileName = '${userId}_face.jpg';
      final savedImage = File('${faceDir.path}/$fileName');
      await faceImage.copy(savedImage.path);

      return savedImage.path;
    } catch (e) {
      print('Save face error: $e');
      return null;
    }
  }

  Future<File?> loadFaceEmbedding(String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final facePath = '${directory.path}/faces/${userId}_face.jpg';
      final faceFile = File(facePath);

      if (await faceFile.exists()) {
        return faceFile;
      }
      return null;
    } catch (e) {
      print('Load face error: $e');
      return null;
    }
  }

  void dispose() {
    _faceDetector.close();
    _embeddingCache.clear();
  }
}

class FaceDetectionResult {
  final bool success;
  final int faceCount;
  final List<Face> faces;

  FaceDetectionResult({
    required this.success,
    required this.faceCount,
    required this.faces,
  });
}

// 🔥 TAMBAHKAN: Multi-face detection result
class MultiFaceDetectionResult {
  final bool success;
  final int faceCount;
  final List<Face> faces;
  final List<Map<String, dynamic>> faceData;

  MultiFaceDetectionResult({
    required this.success,
    required this.faceCount,
    required this.faces,
    required this.faceData,
  });
}
