import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  void setCurrentUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    String? email,
    String? phoneNumber,
    String? address,
    String? kelas,
    String? nip,
  }) async {
    if (_currentUser != null) {
      _currentUser = UserModel(
        id: _currentUser!.id,
        name: name,
        email: email ?? _currentUser!.email,
        role: _currentUser!.role,
        photoUrl: _currentUser!.photoUrl,
        kelas: kelas ?? _currentUser!.kelas,
        nip: nip ?? _currentUser!.nip,
        phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
        address: address ?? _currentUser!.address,
      );
      notifyListeners();
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
