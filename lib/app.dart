import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_strings.dart';
import 'core/di/service_locator.dart';
import 'core/network/connection_status.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/categories/presentation/providers/category_provider.dart';
import 'features/documents/presentation/providers/document_provider.dart';
import 'features/family/presentation/providers/family_provider.dart';

class FamilyDocApp extends StatelessWidget {
  const FamilyDocApp({super.key, this.initialRoute = AppRoutes.welcome});

  /// My Family when a token is already saved, otherwise Welcome.
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ConnectionStatus>.value(
          value: sl<ConnectionStatus>(),
        ),
        ChangeNotifierProvider<AuthProvider>(create: (_) => sl<AuthProvider>()),
        ChangeNotifierProvider<FamilyProvider>(
          create: (_) => sl<FamilyProvider>(),
        ),
        ChangeNotifierProvider<CategoryProvider>(
          create: (_) => sl<CategoryProvider>(),
        ),
        ChangeNotifierProvider<DocumentProvider>(
          create: (_) => sl<DocumentProvider>()..load(),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: initialRoute,
        routes: AppRoutes.routes,
        // Open only the start screen (by default '/dashboard' would also put
        // Welcome underneath it and show a back arrow).
        onGenerateInitialRoutes: (name) => [
          MaterialPageRoute(
            settings: RouteSettings(name: name),
            builder:
                AppRoutes.routes[name] ?? AppRoutes.routes[AppRoutes.welcome]!,
          ),
        ],
      ),
    );
  }
}
