import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class FingerprintService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Cek apakah perangkat support fingerprint
  Future<bool> isDeviceSupported() async {
    try {
      final isAvailable = await _localAuth.isDeviceSupported();
      return isAvailable;
    } catch (e) {
      print('Error checking fingerprint support: $e');
      return false;
    }
  }

  // Cek apakah fingerprint sudah terdaftar di perangkat
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final isAvailable = await _localAuth.isDeviceSupported();
      if (!isAvailable) return false;

      final enrolled = await _localAuth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (e) {
      print('Error checking enrolled biometrics: $e');
      return false;
    }
  }

  // Authenticate dengan fingerprint
  Future<bool> authenticate() async {
    try {
      final isAvailable = await isDeviceSupported();
      if (!isAvailable) {
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Tempelkan jari Anda untuk absensi',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      return authenticated;
    } catch (e) {
      print('Error authenticating: $e');
      return false;
    }
  }

  // Authenticate dengan fallback ke PIN/Pattern
  Future<bool> authenticateWithFallback() async {
    try {
      final isAvailable = await isDeviceSupported();
      if (!isAvailable) {
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Verifikasi identitas untuk absensi',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Bisa pakai PIN/Pattern juga
        ),
      );

      return authenticated;
    } catch (e) {
      print('Error authenticating: $e');
      return false;
    }
  }
}
