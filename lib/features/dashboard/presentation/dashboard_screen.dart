import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/presentation/providers/auth_provider.dart';

/// Placeholder — opened after both auth APIs succeed.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Dashboard', style: AppTextStyles.title),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.welcome, (_) => false);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user_outlined,
                size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            Text('Logged in', style: AppTextStyles.title),
            if (auth.user != null) ...[
              const SizedBox(height: 6),
              Text(auth.user!.mobile, style: AppTextStyles.body),
            ],
          ],
        ),
      ),
    );
  }
}
