import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/data/auth_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/categories/data/category_service.dart';
import '../../features/categories/presentation/providers/category_provider.dart';
import '../../features/documents/data/document_service.dart';
import '../../features/family/data/family_service.dart';
import '../../features/family/presentation/providers/family_provider.dart';
import '../network/api_client.dart';
import '../services/image_service.dart';
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
  sl.registerLazySingleton<ImageService>(() => ImageService());

  // Auth
  sl.registerLazySingleton<AuthService>(() => AuthService(sl()));
  sl.registerFactory<AuthProvider>(
    () => AuthProvider(service: sl(), tokens: sl()),
  );

  // Family
  sl.registerLazySingleton<FamilyService>(() => FamilyService(sl()));
  sl.registerFactory<FamilyProvider>(() => FamilyProvider(service: sl()));

  // Categories
  sl.registerLazySingleton<CategoryService>(() => CategoryService(sl()));
  sl.registerFactory<CategoryProvider>(() => CategoryProvider(service: sl()));

  // Documents
  sl.registerLazySingleton<DocumentService>(() => DocumentService(sl()));
}
