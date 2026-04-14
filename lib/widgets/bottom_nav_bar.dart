// lib/widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isDark;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Colors.blue,
      unselectedItemColor: isDark ? Colors.white54 : Colors.grey,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.face), label: 'Wajah'),
        BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Selfie'),
        BottomNavigationBarItem(icon: Icon(Icons.nfc), label: 'RFID'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
    );
  }
}
