import 'package:flutter/material.dart';

import '../../../core/widgets/app_bottom_nav.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../family/presentation/family_screen.dart';
import '../../profile/presentation/profile_screen.dart';

/// Holds the three main tabs behind one bottom navigation bar.
/// Switching tabs keeps each tab's state; a tab is built the first time
/// it is opened.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialTab = AppTab.family});

  final AppTab initialTab;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late AppTab _current = widget.initialTab;
  late final Set<AppTab> _opened = {widget.initialTab};

  static Widget _screenFor(AppTab tab) => switch (tab) {
    AppTab.dashboard => const DashboardScreen(),
    AppTab.family => const FamilyScreen(),
    AppTab.profile => const ProfileScreen(),
  };

  void _select(AppTab tab) {
    if (tab == _current) return;
    setState(() {
      _current = tab;
      _opened.add(tab);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _current.index,
        children: [
          for (final tab in AppTab.values)
            _opened.contains(tab) ? _screenFor(tab) : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(current: _current, onTap: _select),
    );
  }
}
