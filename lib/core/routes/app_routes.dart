import 'package:flutter/material.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/verifying_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/members/presentation/members_screen.dart';
import '../../features/welcome/presentation/welcome_screen.dart';

/// Every screen is opened by name: `Navigator.pushNamed(context, AppRoutes.login)`.
class AppRoutes {
  AppRoutes._();

  static const String welcome = '/';
  static const String login = '/login';
  static const String verifying = '/verifying'; // argument: 10-digit mobile
  static const String dashboard = '/dashboard';
  static const String members = '/members';

  static Map<String, WidgetBuilder> get routes => {
        welcome: (_) => const WelcomeScreen(),
        login: (_) => const LoginScreen(),
        verifying: (_) => const VerifyingScreen(),
        dashboard: (_) => const DashboardScreen(),
        members: (_) => const MembersScreen(),
      };
}
