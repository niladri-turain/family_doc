import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_text_styles.dart';

enum AppTab { dashboard, family, profile }

/// Dashboard · Family · Profile bottom navigation bar used by MainShell.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.current, required this.onTap});

  final AppTab current;
  final ValueChanged<AppTab> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: current.index,
        onTap: (i) => onTap(AppTab.values[i]),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.white,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            activeIcon: Icon(Icons.people_alt_rounded),
            label: 'Family',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
