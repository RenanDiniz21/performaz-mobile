import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';

import '../core/auth/auth_bloc.dart';
import '../core/auth/auth_repository.dart';
import '../core/network/api_client.dart';
import '../core/network/connectivity_service.dart';
import '../core/repositories/crud_repository.dart';
import '../core/repositories/gamification_repository.dart';
import '../core/repositories/manager_repository.dart';
import '../core/repositories/order_repository.dart';
import '../core/storage/secure_storage.dart';
import '../core/storage/local_database.dart';
import '../core/sync/sync_service.dart';

final getIt = GetIt.instance;

QueryExecutor _openDatabase({required bool useInMemoryDatabase}) {
  if (useInMemoryDatabase) return NativeDatabase.memory();

  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}performaz.sqlite');
    return NativeDatabase.createInBackground(file);
  });
}

void setupDependencies({bool useInMemoryDatabase = false}) {
  if (getIt.isRegistered<SecureStorage>()) return;

  // Storage
  getIt.registerLazySingleton<SecureStorage>(() => SecureStorage());

  // Network
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(secureStorage: getIt<SecureStorage>()),
  );

  // Connectivity
  getIt.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(),
  );

  // Storage (Local DB)
  getIt.registerLazySingleton<LocalDatabase>(
    () => LocalDatabase(
      _openDatabase(useInMemoryDatabase: useInMemoryDatabase),
    ),
  );

  // Sync
  getIt.registerLazySingleton<SyncService>(
    () => SyncService(
      apiClient: getIt<ApiClient>(),
      localDb: getIt<LocalDatabase>(),
      connectivity: getIt<ConnectivityService>(),
    ),
  );

  // Auth
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      apiClient: getIt<ApiClient>(),
      secureStorage: getIt<SecureStorage>(),
    ),
  );

  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );

  // Repositories
  getIt.registerLazySingleton<GamificationRepository>(
    () => GamificationRepository(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<ManagerRepository>(
    () => ManagerRepository(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<CrudRepository>(
    () => CrudRepository(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<OrderRepository>(
    () => OrderRepository(apiClient: getIt<ApiClient>()),
  );
}
