import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class GPSService {
  // Cek apakah GPS diizinkan
  Future<bool> checkPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Layanan lokasi tidak aktif');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Izin lokasi ditolak');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Izin lokasi ditolak permanen');
        return false;
      }

      return true;
    } catch (e) {
      print('Error checking permission: $e');
      return false;
    }
  }

  // DAPATKAN LOKASI DENGAN AKURASI TINGGI
  Future<Position?> getCurrentLocation({bool highAccuracy = true}) async {
    bool hasPermission = await checkPermission();
    if (!hasPermission) {
      return null;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: highAccuracy
            ? LocationAccuracy.bestForNavigation
            : LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      print(
          '📍 Lokasi didapatkan: ${position.latitude}, ${position.longitude}');
      print('🎯 Akurasi: ${position.accuracy} meter');

      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // DAPATKAN LOKASI DENGAN RETRY
  Future<Position?> getCurrentLocationWithRetry({int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      print('🔄 Mencoba mendapatkan lokasi... (${i + 1}/$maxRetries)');

      final position = await getCurrentLocation();
      if (position != null && position.accuracy <= 50) {
        print('✅ Lokasi akurat: ${position.accuracy.toStringAsFixed(0)} meter');
        return position;
      }

      if (position != null) {
        print(
            '⚠️ Akurasi rendah: ${position.accuracy.toStringAsFixed(0)} meter, coba lagi...');
      }

      await Future.delayed(const Duration(seconds: 2));
    }

    return await getCurrentLocation();
  }

  // KONVERSI KOORDINAT KE ALAMAT LENGKAP (DIPERBAIKI - TANPA !)
  Future<String> getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        List<String> addressParts = [];

        // 🔥 PERBAIKAN: Hapus operator ! dan gunakan ?? null check
        if (place.street != null && place.street!.isNotEmpty)
          addressParts.add(place.street!);
        if (place.subLocality != null && place.subLocality!.isNotEmpty)
          addressParts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty)
          addressParts.add(place.locality!);
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty)
          addressParts.add(place.administrativeArea!);

        if (addressParts.isEmpty) {
          return 'Alamat tidak lengkap';
        }
        return addressParts.join(', ');
      }
      return 'Alamat tidak ditemukan';
    } catch (e) {
      print('Error getting address: $e');
      return 'Tidak dapat mengambil alamat';
    }
  }

  // AMBIL NAMA JALAN SAJA
  Future<String> getStreetName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        if (place.street != null && place.street!.isNotEmpty) {
          return place.street!;
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          return place.subLocality!;
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          return place.locality!;
        }
        return 'Alamat tidak diketahui';
      }
      return 'Alamat tidak ditemukan';
    } catch (e) {
      print('Error getting street name: $e');
      return 'Error: $e';
    }
  }

  // AMBIL ALAMAT SINGKAT (DIPERBAIKI - TANPA !)
  Future<String> getShortAddress(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // 🔥 PERBAIKAN: Gunakan ?? untuk null safety
        String street = place.street ?? '';
        String subLocality = place.subLocality ?? '';
        String locality = place.locality ?? '';

        String city = locality.isNotEmpty ? locality : subLocality;

        if (street.isNotEmpty && city.isNotEmpty) {
          return '$street, $city';
        } else if (street.isNotEmpty) {
          return street;
        } else if (city.isNotEmpty) {
          return city;
        }
        return 'Alamat tidak diketahui';
      }
      return 'Alamat tidak ditemukan';
    } catch (e) {
      print('Error getting short address: $e');
      return 'Tidak dapat mengambil alamat';
    }
  }

  // Hitung jarak antara dua titik (dalam meter)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    try {
      return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    } catch (e) {
      print('Error calculating distance: $e');
      return double.infinity;
    }
  }

  // Cek apakah lokasi berada dalam radius tertentu
  bool isWithinRadius(double userLat, double userLon, double targetLat,
      double targetLon, double radius) {
    double distance = calculateDistance(userLat, userLon, targetLat, targetLon);
    return distance <= radius;
  }

  // CEK APAKAH LOKASI AKURAT
  bool isLocationAccurate(Position position, {double maxMeters = 50}) {
    return position.accuracy <= maxMeters;
  }

  // DAPATKAN STATUS AKURASI
  String getAccuracyStatus(double accuracy) {
    if (accuracy <= 10) return 'Sangat Akurat';
    if (accuracy <= 30) return 'Akurat';
    if (accuracy <= 50) return 'Cukup Akurat';
    if (accuracy <= 100) return 'Kurang Akurat';
    return 'Tidak Akurat';
  }

  // DAPATKAN WARNA UNTUK AKURASI
  int getAccuracyColor(double accuracy) {
    if (accuracy <= 10) return 0xFF4CAF50;
    if (accuracy <= 30) return 0xFF8BC34A;
    if (accuracy <= 50) return 0xFFFFC107;
    if (accuracy <= 100) return 0xFFFF9800;
    return 0xFFF44336;
  }

  // Get status layanan lokasi
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Buka pengaturan lokasi
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}
