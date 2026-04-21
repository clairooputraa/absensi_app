import 'package:flutter/foundation.dart';
import '../main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'user_token';
  static const String _userIdKey = 'user_id';
  static const String _userRoleKey = 'user_role';
  static const String _userNameKey = 'user_name';

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<String?> getCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  Future<String?> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  Future<void> saveSession({
    required String userId,
    required String userRole,
    required String userName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _tokenKey, 'dummy_token_${DateTime.now().millisecondsSinceEpoch}');
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userRoleKey, userRole);
    await prefs.setString(_userNameKey, userName);
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userNameKey);
  }

  // LOGIN
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await supabaseClient
          .from('users')
          .select()
          .eq('email', email)
          .eq('password', password)
          .maybeSingle();

      if (response != null) {
        await saveSession(
          userId: response['id'].toString(),
          userRole: response['role'] ?? 'User',
          userName: response['name'] ?? 'Unknown',
        );
        return {
          'success': true,
          'user': response,
          'message': 'Login berhasil',
        };
      }
      return {
        'success': false,
        'user': null,
        'message': 'Email atau password salah',
      };
    } catch (e) {
      debugPrint('Login error: $e');
      return {
        'success': false,
        'user': null,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // REGISTER dengan parameter lengkap
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
    String? address,
    String? nip,
    String? kelas,
  }) async {
    try {
      // Cek email sudah terdaftar
      final existing = await supabaseClient
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (existing != null) {
        return {
          'success': false,
          'user': null,
          'message': 'Email sudah terdaftar',
        };
      }

      // Data user baru
      final Map<String, dynamic> userData = {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Tambahkan field opsional jika ada
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        userData['phone_number'] = phoneNumber;
      }
      if (address != null && address.isNotEmpty) {
        userData['address'] = address;
      }
      if (nip != null && nip.isNotEmpty && role == 'Petugas') {
        userData['nip'] = nip;
      }
      if (kelas != null && kelas.isNotEmpty && role == 'User') {
        userData['kelas'] = kelas;
      }

      // Insert user
      final response =
          await supabaseClient.from('users').insert(userData).select().single();

      return {
        'success': true,
        'user': response,
        'message': 'Registrasi berhasil',
      };
    } catch (e) {
      debugPrint('Register error: $e');
      return {
        'success': false,
        'user': null,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
}
