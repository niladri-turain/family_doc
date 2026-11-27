import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../../features/assistant/data/assistant_engine.dart';
import '../../features/assistant/data/local_assistant.dart';
import '../../features/auth/data/auth_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/categories/data/category_service.dart';
import '../../features/categories/presentation/providers/category_provider.dart';
import '../../features/documents/data/document_service.dart';
import '../../features/documents/data/document_store.dart';
import '../../features/documents/data/document_type_store.dart';
import '../../features/documents/data/file_actions.dart';
import '../../features/documents/data/reading/document_reader.dart';
import '../../features/documents/presentation/providers/document_provider.dart';
import '../../features/family/data/family_service.dart';
import '../../features/family/presentation/providers/family_provider.dart';
import '../../features/reminders/reminder_service.dart';
import '../network/api_client.dart';
import '../network/connection_status.dart';
import '../storage/api_cache.dart';
import '../services/image_service.dart';
import '../services/photo_cache.dart';
import '../storage/token_storage.dart';

/// Global service locator. Get anything with `sl<ApiClient>()`.
final GetIt sl = GetIt.instance;

/// Registers every dependency once at app start.
/// Tests can pass a fake [httpClient] / [tokenStorage].
Future<void> setupLocator({
  http.Client? httpClient,
  TokenStorage? tokenStorage,
  ApiCache? apiCache,
  DocumentStore? documentStore,
  DocumentTypeStore? documentTypeStore,
  FileActions? fileActions,
  DocumentReader? documentReader,
  ReminderService? reminderService,
  AssistantEngine? assistant,
}) async {
  await sl.reset();

  // Core
  sl.registerLazySingleton<TokenStorage>(() => tokenStorage ?? TokenStorage());
  sl.registerLazySingleton<http.Client>(() => httpClient ?? http.Client());
  sl.registerLazySingleton<ConnectionStatus>(() => ConnectionStatus());
  sl.registerLazySingleton<ApiCache>(() => apiCache ?? HiveApiCache());
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(tokenStorage: sl(), client: sl(), status: sl()),
  );
  sl.registerLazySingleton<ImageService>(() => ImageService());
  sl.registerLazySingleton<PhotoCache>(() => PhotoCache(sl()));

  // Auth
  sl.registerLazySingleton<AuthService>(() => AuthService(sl(), sl()));
  sl.registerFactory<AuthProvider>(
    () => AuthProvider(service: sl(), tokens: sl(), cache: sl()),
  );

  // Family
  sl.registerLazySingleton<FamilyService>(() => FamilyService(sl(), sl()));
  sl.registerFactory<FamilyProvider>(() => FamilyProvider(service: sl()));

  // Categories
  sl.registerLazySingleton<CategoryService>(() => CategoryService(sl(), sl()));
  sl.registerFactory<CategoryProvider>(() => CategoryProvider(service: sl()));

  // Documents
  sl.registerLazySingleton<DocumentService>(() => DocumentService(sl(), sl()));
  sl.registerLazySingleton<DocumentStore>(
    () => documentStore ?? HiveDocumentStore(),
  );
  sl.registerLazySingleton<FileActions>(() => fileActions ?? FileActions());
  sl.registerLazySingleton<DocumentReader>(
    () => documentReader ?? DocumentReader(),
  );
  sl.registerLazySingleton<DocumentTypeStore>(
    () => documentTypeStore ?? HiveDocumentTypeStore(),
  );
  sl.registerFactory<DocumentProvider>(
    () => DocumentProvider(store: sl(), typeStore: sl()),
  );

  // Expiry reminders and the on-phone assistant
  sl.registerLazySingleton<ReminderService>(
    () => reminderService ?? ReminderService(),
  );
  sl.registerLazySingleton<AssistantEngine>(
    () => assistant ?? const LocalAssistant(),
  );
}
