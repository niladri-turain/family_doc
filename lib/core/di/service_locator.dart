import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/data/auth_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';

/// Global service locator. Get anything with `sl<ApiClient>()`.
final GetIt sl = GetIt.instance;

/// Registers every dependency once at app start.
/// Tests can pass a fake [httpClient] / [tokenStorage].
Future<void> setupLocator({
  http.Client? httpClient,
  TokenStorage? tokenStorage,
}) async {
  await sl.reset();

  // Core
  sl.registerLazySingleton<TokenStorage>(() => tokenStorage ?? TokenStorage());
  sl.registerLazySingleton<http.Client>(() => httpClient ?? http.Client());
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(tokenStorage: sl(), client: sl()),
  );

  // Auth
  sl.registerLazySingleton<AuthService>(() => AuthService(sl()));
  sl.registerFactory<AuthProvider>(
    () => AuthProvider(service: sl(), tokens: sl()),
  );
}
