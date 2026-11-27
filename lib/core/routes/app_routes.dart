import 'package:flutter/material.dart';

import '../../features/assistant/presentation/assistant_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/verifying_screen.dart';
import '../../features/documents/presentation/category_documents_screen.dart';
import '../../features/family/presentation/add_member_screen.dart';
import '../../features/home/presentation/main_shell.dart';
import '../../features/profile/presentation/delete_members_screen.dart';
import '../../features/welcome/presentation/welcome_screen.dart';
import '../widgets/app_bottom_nav.dart';

/// Every screen is opened by name: `Navigator.pushNamed(context, AppRoutes.login)`.
class AppRoutes {
  AppRoutes._();

  static const String welcome = '/';
  static const String login = '/login';
  static const String verifying = '/verifying'; // argument: 10-digit mobile
  static const String dashboard = '/dashboard';
  static const String family = '/family';
  static const String addMember = '/family/add'; // argument: bool addingSelf
  static const String editMember = '/family/edit'; // argument: FamilyMember
  static const String profile = '/profile';
  static const String deleteMembers = '/profile/delete-members';
  static const String assistant = '/assistant'; // argument: AssistantArgs?
  static const String categoryDocuments =
      '/documents'; // argument: CategoryDocumentsArgs

  static Map<String, WidgetBuilder> get routes => {
    welcome: (_) => const WelcomeScreen(),
    login: (_) => const LoginScreen(),
    verifying: (_) => const VerifyingScreen(),
    dashboard: (_) => const MainShell(initialTab: AppTab.dashboard),
    family: (_) => const MainShell(initialTab: AppTab.family),
    addMember: (_) => const AddMemberScreen(),
    editMember: (_) => const AddMemberScreen(),
    profile: (_) => const MainShell(initialTab: AppTab.profile),
    deleteMembers: (_) => const DeleteMembersScreen(),
    categoryDocuments: (_) => const CategoryDocumentsScreen(),
    assistant: (_) => const AssistantScreen(),
  };
}
