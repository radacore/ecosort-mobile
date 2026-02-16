import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecosort/screens/beranda_screen.dart';
import 'package:ecosort/screens/scan_screen.dart';
import 'package:ecosort/screens/panduan_screen.dart';
import 'package:ecosort/screens/profile_screen.dart';
import 'package:ecosort/screens/scoreboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _children = const [
    BerandaScreen(),
    ScoreboardScreen(),
    ScanScreen(),
    PanduanScreen(),
    ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If not on Beranda tab, go back to Beranda first
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return;
        }

        // If already on Beranda, show exit confirmation
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Keluar Aplikasi'),
            content: const Text('Apakah Anda yakin ingin keluar dari EcoSort?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Tidak',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Ya',
                  style: TextStyle(color: Color(0xFF2E7D32)),
                ),
              ),
            ],
          ),
        );

        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        extendBody: true,
        body: _children[_currentIndex],
        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    0,
                    Icons.home_rounded,
                    Icons.home_outlined,
                    'Beranda',
                  ),
                  _buildNavItem(
                    1,
                    Icons.emoji_events_rounded,
                    Icons.emoji_events_outlined,
                    'Skor',
                  ),
                  _buildScanButton(),
                  _buildNavItem(
                    3,
                    Icons.menu_book_rounded,
                    Icons.menu_book_outlined,
                    'Panduan',
                  ),
                  _buildNavItem(
                    4,
                    Icons.person_rounded,
                    Icons.person_outlined,
                    'Profil',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: isActive ? 16 : 0,
                  vertical: isActive ? 6 : 0,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF2E7D32).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isActive ? activeIcon : inactiveIcon,
                  color: isActive ? const Color(0xFF2E7D32) : Colors.grey[400],
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? const Color(0xFF2E7D32) : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    final isActive = _currentIndex == 2;
    return GestureDetector(
      onTap: () => _onTabTapped(2),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: isActive ? Border.all(color: Colors.white, width: 2.5) : null,
        ),
        child: const Icon(
          Icons.document_scanner_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}
