import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;
  final ImagePicker _picker = ImagePicker();

  UserModel? get currentUser => _currentUser;

  void setCurrentUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  // 🔥 AMBIL FOTO DARI GALERI
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  // 🔥 AMBIL FOTO DARI KAMERA
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  // 🔥 UPDATE FOTO PROFIL
  Future<bool> updateProfilePhoto(File imageFile) async {
    if (_currentUser == null) return false;

    try {
      // Simpan ke local storage
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${_currentUser!.id}.jpg';
      final savedImage = File('${appDir.path}/$fileName');

      // Copy file ke direktori app
      await imageFile.copy(savedImage.path);

      // Update user model dengan path foto
      _currentUser = _currentUser!.copyWith(
        photoUrl: savedImage.path,
      );

      notifyListeners();
      return true;
    } catch (e) {
      print('Error saving profile photo: $e');
      return false;
    }
  }

  // 🔥 HAPUS FOTO PROFIL
  Future<bool> deleteProfilePhoto() async {
    if (_currentUser == null || _currentUser!.photoUrl == null) return false;

    try {
      final photoFile = File(_currentUser!.photoUrl!);
      if (await photoFile.exists()) {
        await photoFile.delete();
      }

      _currentUser = _currentUser!.copyWith(photoUrl: null);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting profile photo: $e');
      return false;
    }
  }

  // 🔥 METHOD UPDATE USER (menggunakan copyWith)
  Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    if (_currentUser != null && _currentUser!.id == userId) {
      _currentUser = _currentUser!.copyWith(
        name: data['name'] ?? _currentUser!.name,
        email: data['email'] ?? _currentUser!.email,
        phoneNumber: data['phone_number'] ?? _currentUser!.phoneNumber,
        nip: data['nip'] ?? _currentUser!.nip,
        kelas: data['class'] ?? _currentUser!.kelas,
        photoUrl: data['photo_url'] ?? _currentUser!.photoUrl,
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  // Method update profile yang sudah ada
  Future<void> updateProfile({
    required String name,
    String? email,
    String? phoneNumber,
    String? address,
    String? kelas,
    String? nip,
  }) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        address: address,
        kelas: kelas,
        nip: nip,
      );
      notifyListeners();
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
