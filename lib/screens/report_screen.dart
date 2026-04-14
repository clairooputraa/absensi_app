import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/role_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    if (roleProvider.userRole != 'Petugas') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
    }
  }

  List<DateTime> _getDaysInMonth() {
    final firstDay = DateTime(_selectedYear, _selectedMonth, 1);
    final lastDay = DateTime(_selectedYear, _selectedMonth + 1, 0);
    final days = <DateTime>[];
    for (int i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(_selectedYear, _selectedMonth, i));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final roleProvider = Provider.of<RoleProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final isPetugas = roleProvider.userRole == 'Petugas';

    if (!isPetugas) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A2A) : const Color(0xFFF0F4FF),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // Header Premium
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2196F3),
                        Color(0xFF1565C0),
                        Color(0xFF0D47A1)
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'Laporan Kehadiran',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_months[_selectedMonth - 1]} $_selectedYear',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Stats Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildStatCard('HADIR', '0', Colors.green, isDark),
                    const SizedBox(width: 12),
                    _buildStatCard('ABSEN', '0', Colors.red, isDark),
                    const SizedBox(width: 12),
                    _buildStatCard('TERLAMBAT', '0', Colors.orange, isDark),
                  ],
                ),
              ),
            ),

            // Calendar Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Month Selector
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF1A1A3E),
                                  const Color(0xFF0D0D2B)
                                ]
                              : [Colors.white, const Color(0xFFF8F9FF)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: isDark
                                  ? Colors.black26
                                  : Colors.blue.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_months[_selectedMonth - 1]} $_selectedYear',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: () {
                                  setState(() {
                                    if (_selectedMonth == 1) {
                                      _selectedMonth = 12;
                                      _selectedYear--;
                                    } else {
                                      _selectedMonth--;
                                    }
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: () {
                                  setState(() {
                                    if (_selectedMonth == 12) {
                                      _selectedMonth = 1;
                                      _selectedYear++;
                                    } else {
                                      _selectedMonth++;
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Calendar Grid
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF1A1A3E),
                                  const Color(0xFF0D0D2B)
                                ]
                              : [Colors.white, const Color(0xFFF8F9FF)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Day headers
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              'Sen',
                              'Sel',
                              'Rab',
                              'Kam',
                              'Jum',
                              'Sab',
                              'Min'
                            ].map((day) {
                              return Expanded(
                                child: Center(
                                  child: Text(
                                    day,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          ..._buildCalendarRows(isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Delete All Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('HAPUS SEMUA DATA'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCalendarRows(bool isDark) {
    final days = _getDaysInMonth();
    final firstDayWeekday = days.first.weekday;
    final startOffset = firstDayWeekday - 1;

    final rows = <Widget>[];
    var currentIndex = 0;

    // Add empty cells
    for (int i = 0; i < startOffset; i++) {
      if (currentIndex == 0) {
        rows.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) => Expanded(child: Container())),
        ));
      }
    }

    while (currentIndex < days.length) {
      final weekDays = <Widget>[];
      for (int i = 0; i < 7 && currentIndex < days.length; i++) {
        final date = days[currentIndex];
        final isSelected = _selectedDate.year == date.year &&
            _selectedDate.month == date.month &&
            _selectedDate.day == date.day;
        weekDays.add(
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDate = date),
              child: Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF1565C0)])
                      : null,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        currentIndex++;
      }
      rows.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays));
      rows.add(const SizedBox(height: 4));
    }
    return rows;
  }

  Widget _buildStatCard(String title, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A1A3E), const Color(0xFF0D0D2B)]
                : [Colors.white, const Color(0xFFF8F9FF)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: isDark ? Colors.black26 : Colors.blue.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title,
                style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
