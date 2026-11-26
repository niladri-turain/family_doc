import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/routes/app_routes.dart';
import 'core/storage/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();

  final loggedIn = await sl<TokenStorage>().hasToken;
  runApp(
    FamilyDocApp(initialRoute: loggedIn ? AppRoutes.family : AppRoutes.welcome),
  );
}
