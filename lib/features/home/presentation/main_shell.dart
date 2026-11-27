import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/routes/app_routes.dart';
import '../../assistant/presentation/assistant_screen.dart';
import '../../documents/data/models/saved_document.dart';
import '../../documents/presentation/providers/document_provider.dart';
import '../../family/presentation/providers/family_provider.dart';
import '../../reminders/reminder_planner.dart';
import '../../reminders/reminder_service.dart';

import '../../../core/widgets/app_bottom_nav.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../family/presentation/family_screen.dart';
import '../../profile/presentation/profile_screen.dart';

/// Holds the three main tabs behind one bottom navigation bar.
/// Switching tabs keeps each tab's state; a tab is built the first time
/// it is opened. While it is open, expiry reminders follow the saved
/// documents, and tapping a reminder opens the chat.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialTab = AppTab.family});

  final AppTab initialTab;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late AppTab _current = widget.initialTab;
  late final Set<AppTab> _opened = {widget.initialTab};

  late final DocumentProvider _documents = context.read<DocumentProvider>();
  late final FamilyProvider _family = context.read<FamilyProvider>();
  final ReminderService _reminders = sl<ReminderService>();

  /// The reminders last scheduled, to skip rescheduling the same ones.
  String? _scheduled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _documents.addListener(_syncReminders);
      _family.addListener(_syncReminders);
      _syncReminders();
      _reminders.onTap = _openFromReminder;
      await _reminders.init();
      final launched = await _reminders.launchPayload();
      if (launched == reminderPayload) _openFromReminder(launched);
    });
  }

  @override
  void dispose() {
    _documents.removeListener(_syncReminders);
    _family.removeListener(_syncReminders);
    _reminders.onTap = null;
    super.dispose();
  }

  void _syncReminders() {
    // Wait for both, so documents of removed members aren't reminded.
    if (!_documents.hasLoaded || !_family.hasLoaded) return;
    final ids = {for (final m in _family.members) m.id};
    final planned = ReminderPlanner.plan([
      for (final d in _documents.all)
        if (ids.contains(d.memberId)) d,
    ], ownerOf: _ownerOf);
    final key = planned.map((r) => '${r.at}|${r.title}|${r.body}').join('\n');
    if (key == _scheduled) return;
    _scheduled = key;
    _reminders.schedule(planned);
  }

  String _ownerOf(SavedDocument d) {
    for (final m in _family.members) {
      if (m.id == d.memberId) return m.isSelf ? 'your' : "${m.fullName}'s";
    }
    return '';
  }

  void _openFromReminder(String? payload) {
    if (!mounted || payload != reminderPayload) return;
    Navigator.pushNamed(
      context,
      AppRoutes.assistant,
      arguments: const AssistantArgs(question: "What's expiring soon?"),
    );
  }

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
