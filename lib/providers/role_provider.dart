import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoleProvider extends ChangeNotifier {
  String _userRole = 'Petugas';
  static const String _roleKey = 'user_role';

  RoleProvider() {
    _loadRole();
  }

  String get userRole => _userRole;
  bool get isPetugas => _userRole == 'Petugas';
  bool get isUser => _userRole == 'User';

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    _userRole = prefs.getString(_roleKey) ?? 'Petugas';
    notifyListeners();
  }

  Future<void> setUserRole(String role) async {
    _userRole = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
    notifyListeners();
  }

  Future<void> toggleRole() async {
    _userRole = _userRole == 'Petugas' ? 'User' : 'Petugas';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, _userRole);
    notifyListeners();
  }

  Future<void> resetRole() async {
    _userRole = 'Petugas';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    notifyListeners();
  }
}
