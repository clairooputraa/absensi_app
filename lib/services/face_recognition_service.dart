import 'dart:io';
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

  Future<double> verifyFace(File face1, File face2) async {
    // TODO: Implementasi face comparison dengan ML model
    await Future.delayed(const Duration(milliseconds: 500));
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
