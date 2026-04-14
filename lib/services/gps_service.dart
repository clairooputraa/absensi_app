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

  // Dapatkan lokasi saat ini
  Future<Position?> getCurrentLocation() async {
    bool hasPermission = await checkPermission();
    if (!hasPermission) {
      return null;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Konversi koordinat ke alamat
  Future<String> getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
        ].where((part) => part != null && part.isNotEmpty).join(', ');

        return address.isNotEmpty ? address : 'Alamat tidak lengkap';
      }
      return 'Alamat tidak ditemukan';
    } catch (e) {
      print('Error getting address: $e');
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

  // Cek apakah lokasi berada dalam radius tertentu (meter)
  bool isWithinRadius(double userLat, double userLon, double targetLat,
      double targetLon, double radius) {
    double distance = calculateDistance(userLat, userLon, targetLat, targetLon);
    return distance <= radius;
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
