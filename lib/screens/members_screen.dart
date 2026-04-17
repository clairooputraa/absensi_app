import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/role_provider.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen>
    with TickerProviderStateMixin {
  // GANTI dari SingleTickerProviderStateMixin ke TickerProviderStateMixin
  // int _selectedTab = 0; // Removed unused field
  String _searchQuery = '';
  String _selectedClass = 'Semua';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _classOptions = [
    'Semua',
    'X DKV',
    'X RPL',
    'XI DKV',
    'XI RPL',
    'XII DKV',
    'XII RPL'
  ];

  final List<Map<String, dynamic>> _members = List.generate(
      66,
      (index) => {
            'name': index == 0
                ? 'anam firmansyah'
                : index == 1
                    ? 'ACHMAD AVRYAN DWI WAHYUDI'
                    : index == 2
                        ? 'ACHMAD MARVEL DAVINSYAH'
                        : index == 3
                            ? 'Hans'
                            : index == 4
                                ? 'A. KHARISH FIKRI DZULFAHMI'
                                : index == 5
                                    ? 'Petugas'
                                    : 'ACHMAD WIDIANTO RAMADHAN',
            'class': index % 3 == 0
                ? 'X DKV'
                : index % 3 == 1
                    ? 'X RPL'
                    : 'XI DKV',
            'role': index == 3
                ? 'admin'
                : index == 5
                    ? 'admin'
                    : 'member',
            'status': index == 4
                ? 'No Finger'
                : index == 6
                    ? 'No Face'
                    : '',
          });

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    _tabController.dispose();
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
        child: Column(
          children: [
            // Header Premium
            Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2196F3),
                    Color(0xFF1565C0),
                    Color(0xFF0D47A1)
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Manajemen Anggota',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Kelola data anggota dengan mudah',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      // Tab Bar Premium
                      Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          labelColor: const Color(0xFF2196F3),
                          unselectedLabelColor: Colors.white70,
                          tabs: const [
                            Tab(text: 'Overview'),
                            Tab(text: 'Members'),
                            Tab(text: 'Performance'),
                          ],
                          onTap: (index) {
                            // setState(() {
                            //   _selectedTab = index;
                            // });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(isDark),
                  _buildMembersTab(isDark),
                  _buildPerformanceTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatCard('Total Members', '1308', const Color(0xFF2196F3),
              Icons.people, isDark),
          const SizedBox(height: 16),
          _buildStatCard('ACTIVE MEMBERS', '1308', const Color(0xFF4CAF50),
              Icons.check_circle, isDark),
          const SizedBox(height: 16),
          _buildStatCard('PUNCTUALITY RATE', '0.0%', const Color(0xFFFF9800),
              Icons.timer, isDark,
              subtitle: 'On-time attendance'),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1A1A3E), const Color(0xFF0D0D2B)]
                    : [Colors.white, const Color(0xFFF8F9FF)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color:
                        isDark ? Colors.black26 : Colors.blue.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: const Column(
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('No activities today',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon, bool isDark,
      {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1A3E), const Color(0xFF0D0D2B)]
              : [Colors.white, const Color(0xFFF8F9FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: isDark ? Colors.black26 : Colors.blue.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey[600])),
                Text(value,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color)),
                if (subtitle != null)
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.grey[500])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab(bool isDark) {
    final filteredMembers = _members.where((member) {
      final matchesSearch = _searchQuery.isEmpty ||
          member['name'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesClass =
          _selectedClass == 'Semua' || member['class'] == _selectedClass;
      return matchesSearch && matchesClass;
    }).toList();

    final totalPages = (filteredMembers.length / _itemsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    final pagedMembers = filteredMembers.sublist(startIndex,
        endIndex > filteredMembers.length ? filteredMembers.length : endIndex);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Cari anggota...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _classOptions.map((className) {
                    final isSelected = _selectedClass == className;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(className),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedClass = className;
                            _currentPage = 1;
                          });
                        },
                        backgroundColor:
                            isDark ? Colors.grey[800] : Colors.grey[200],
                        selectedColor: const Color(0xFF2196F3),
                        labelStyle:
                            TextStyle(color: isSelected ? Colors.white : null),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: pagedMembers.length,
            itemBuilder: (context, index) {
              final member = pagedMembers[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1A1A3E), const Color(0xFF0D0D2B)]
                        : [Colors.white, const Color(0xFFF8F9FF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: isDark ? Colors.black26 : Colors.grey.shade100,
                        blurRadius: 4,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF2196F3).withValues(alpha: 0.1),
                    child: Text(member['name'][0].toUpperCase(),
                        style: const TextStyle(color: Color(0xFF2196F3))),
                  ),
                  title: Text(member['name'],
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(member['class'],
                      style: const TextStyle(fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (member['status'].isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: Text(member['status'],
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.red)),
                        ),
                      if (member['role'] == 'admin')
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Text('admin',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.blue)),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
                child: const Text('< Prev'),
              ),
              Text('Page $_currentPage of $totalPages',
                  style: const TextStyle(fontSize: 12)),
              TextButton(
                onPressed: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
                child: const Text('Next >'),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Text('${filteredMembers.length} Total Members',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildPerformanceTab(bool isDark) {
    final List<Map<String, dynamic>> rankings = List.generate(
        10,
        (index) => ({
              'rank': index + 1,
              'name': index == 0
                  ? 'IZZA NAZILA FAJRIN'
                  : index == 1
                      ? 'ACHMAD AVRYAN DWI WAHYUDI'
                      : index == 2
                          ? 'ACHMAD MARVEL DAVINSYAH'
                          : index == 3
                              ? 'Hans'
                              : index == 4
                                  ? 'A. KHARISH FIKRI DZULFAHMI'
                                  : index == 5
                                      ? 'Petugas'
                                      : 'ACHMAD WIDIANTO RAMADHAN',
              'score': '0.0%',
              'logs': 0,
              'hours': 0.0,
            }));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Today', true, isDark),
                      _buildFilterChip('Yesterday', false, isDark),
                      _buildFilterChip('This Week', false, isDark),
                      _buildFilterChip('Last Week', false, isDark),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: 'Score',
                    items: const [
                      DropdownMenuItem(
                          value: 'Score', child: Text('Sort by Score'))
                    ],
                    onChanged: (value) {},
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: rankings.length,
            itemBuilder: (context, index) {
              final item = rankings[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1A1A3E), const Color(0xFF0D0D2B)]
                        : [Colors.white, const Color(0xFFF8F9FF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF2196F3), Color(0xFF1565C0)]),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text('${item['rank']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.history, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('${item['logs']} Logs',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                              const SizedBox(width: 12),
                              const Icon(Icons.access_time,
                                  size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('${item['hours']}hrs',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('SCORE',
                            style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(item['score'],
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2196F3))),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {},
        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
        selectedColor: const Color(0xFF2196F3),
        labelStyle: TextStyle(color: isSelected ? Colors.white : null),
      ),
    );
  }
}
