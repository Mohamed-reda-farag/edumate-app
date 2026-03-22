import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final int currentIndex;
  final Widget child;

  const MainScaffold({super.key, required this.currentIndex, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: child,
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBgColor = isDark ? Theme.of(context).colorScheme.surface : Colors.white;
    final borderColor = isDark ? Theme.of(context).dividerColor : const Color(0xFFEEEEF5);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: navBgColor,
          border: Border(
            top: BorderSide(
              color: borderColor,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            switch (index) {
              case 0:
                context.go('/profile');
                break;
              case 1:
                context.go('/schedule');
                break;
              case 2:
                context.go('/home');
                break;
              case 3:
                context.go('/tasks');
                break;
              case 4:
                context.go('/fields-hub');
                break;
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: navBgColor,
          selectedItemColor: const Color(0xFF6C63FF),
          unselectedItemColor: const Color(0xFFB0B0C3),
          selectedFontSize: 11,
          unselectedFontSize: 10,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
          ),
          items: [
            _buildNavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'الملف الشخصي',
              isSelected: currentIndex == 0,
            ),
            _buildNavItem(
              icon: Icons.calendar_today_outlined,
              activeIcon: Icons.calendar_today_rounded,
              label: 'الجدول',
              isSelected: currentIndex == 1,
            ),
            _buildNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'الرئيسية',
              isSelected: currentIndex == 2,
            ),
            _buildNavItem(
              icon: Icons.checklist_outlined,
              activeIcon: Icons.checklist_rounded,
              label: 'المهام',
              isSelected: currentIndex == 3,
            ),
            _buildNavItem(
              icon: Icons.school_outlined,
              activeIcon: Icons.school_rounded,
              label: 'مجالاتي',
              isSelected: currentIndex == 4,
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
  }) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24),
        ),
      ),
      activeIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(activeIcon, size: 24),
        ),
      ),
      label: label,
    );
  }
}