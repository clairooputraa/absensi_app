import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'providers/theme_provider.dart';
import 'providers/role_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/user_provider.dart';
import 'screens/home_screen.dart';
import 'screens/members_screen.dart';
import 'screens/report_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/attendance_method_screen.dart';

const String SUPABASE_URL = 'https://jvyvebcozmjwdunybukg.supabase.co';
const String SUPABASE_ANON_KEY =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp2eXZlYmNvem1qd2R1bnlidWtnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYwNDU1MTAsImV4cCI6MjA5MTYyMTUxMH0.fa_1-6cPC3m_0I56BOZZOdFEDl4pEdNYZnF7u7SeV5I';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SUPABASE_URL,
    anonKey: SUPABASE_ANON_KEY,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => RoleProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'AbsenMu Digital',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            initialRoute: '/login',
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const MainScreen(),
              '/attendance': (context) => const AttendanceMethodScreen(),
              '/profile': (context) => const ProfileScreen(),
            },
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late List<Widget> _screens;
  late List<Map<String, dynamic>> _navItems;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final roleProvider = Provider.of<RoleProvider>(context);
    final isPetugas = roleProvider.userRole == 'Petugas';

    if (isPetugas) {
      // PETUGAS/ADMIN: 4 MENU LENGKAP
      _screens = [
        const HomeScreen(),
        const MembersScreen(),
        const ReportScreen(),
        const ProfileScreen(),
      ];
      _navItems = [
        {'icon': Icons.home, 'label': 'Beranda', 'index': 0},
        {'icon': Icons.people, 'label': 'Anggota', 'index': 1},
        {'icon': Icons.bar_chart, 'label': 'Laporan', 'index': 2},
        {'icon': Icons.person, 'label': 'Profil', 'index': 3},
      ];
    } else {
      // USER/MURID: HANYA 2 MENU
      _screens = [
        const HomeScreen(),
        const ProfileScreen(),
      ];
      _navItems = [
        {'icon': Icons.home, 'label': 'Beranda', 'index': 0},
        {'icon': Icons.person, 'label': 'Profil', 'index': 1},
      ];

      if (_selectedIndex > 1) {
        _selectedIndex = 0;
      }
    }
  }

  // 🔥 FUNGSI INI TIDAK DIPERLUKAN LAGI KARENA FAB DI HAPUS
  // void _openAttendance() {
  //   Navigator.pushNamed(context, '/attendance');
  // }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final roleProvider = Provider.of<RoleProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final isPetugas = roleProvider.userRole == 'Petugas';

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomAppBar(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 8,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Menu 1: Beranda
              _buildNavItem(_navItems[0]['icon'] as IconData,
                  _navItems[0]['label'] as String, 0, isDark),

              // Menu 2: (Anggota untuk Petugas, atau kosong untuk User)
              if (isPetugas)
                _buildNavItem(_navItems[1]['icon'] as IconData,
                    _navItems[1]['label'] as String, 1, isDark)
              else
                const SizedBox(width: 40),

              // Space untuk FAB
              const SizedBox(width: 40),

              // Menu 3: (Laporan untuk Petugas, atau Profil untuk User)
              if (isPetugas)
                _buildNavItem(_navItems[2]['icon'] as IconData,
                    _navItems[2]['label'] as String, 2, isDark)
              else
                _buildNavItem(_navItems[1]['icon'] as IconData,
                    _navItems[1]['label'] as String, 1, isDark),

              // Menu 4: Profil untuk Petugas
              if (isPetugas)
                _buildNavItem(_navItems[3]['icon'] as IconData,
                    _navItems[3]['label'] as String, 3, isDark),
            ],
          ),
        ),
      ),
      // 🔥🔥🔥 HAPUS FAB DI SINI! 🔥🔥🔥
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _openAttendance,
      //   backgroundColor: const Color(0xFF2196F3),
      //   elevation: 4,
      //   child: const Icon(Icons.camera_alt, size: 28, color: Colors.white),
      // ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isDark) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF2196F3)
                  : (isDark ? Colors.white54 : Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? const Color(0xFF2196F3)
                    : (isDark ? Colors.white54 : Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
