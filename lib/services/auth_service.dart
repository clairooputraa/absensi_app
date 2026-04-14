import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (response == null) {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': 'Email tidak terdaftar'};
      }

      if (response['password'] != password) {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': 'Password salah'};
      }

      _currentUser = UserModel(
        id: response['id'],
        name: response['name'],
        email: response['email'],
        role: response['role'],
        photoUrl: response['photo_url'],
        kelas: response['kelas'],
        nip: response['nip'],
        phoneNumber: response['phone_number'],
        address: response['address'],
      );

      _isLoading = false;
      notifyListeners();

      return {
        'success': true,
        'message': 'Login berhasil',
        'user': _currentUser
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Register
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
    _isLoading = true;
    notifyListeners();

    try {
      // Cek email sudah terdaftar
      final existingUser = await _supabase
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (existingUser != null) {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': 'Email sudah terdaftar'};
      }

      // Insert user baru
      final response = await _supabase
          .from('users')
          .insert({
            'name': name,
            'email': email,
            'password': password,
            'role': role,
            'phone_number': phoneNumber,
            'address': address,
            'nip': nip,
            'kelas': kelas,
          })
          .select()
          .single();

      _currentUser = UserModel(
        id: response['id'],
        name: response['name'],
        email: response['email'],
        role: response['role'],
        photoUrl: response['photo_url'],
        kelas: response['kelas'],
        nip: response['nip'],
        phoneNumber: response['phone_number'],
        address: response['address'],
      );

      _isLoading = false;
      notifyListeners();

      return {
        'success': true,
        'message': 'Registrasi berhasil',
        'user': _currentUser
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Registrasi gagal: $e'};
    }
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }
}
