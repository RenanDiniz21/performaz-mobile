import 'package:get_it/get_it.dart';

import '../core/auth/auth_bloc.dart';
import '../core/auth/auth_repository.dart';
import '../core/network/api_client.dart';
import '../core/network/connectivity_service.dart';
import '../core/storage/secure_storage.dart';
// import '../core/sync/sync_service.dart'; // Uncomment after drift codegen

final getIt = GetIt.instance;

void setupDependencies() {
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

  // Sync (registered without LocalDatabase for now — will be connected after code gen)
  // getIt.registerLazySingleton<SyncService>(
  //   () => SyncService(
  //     apiClient: getIt<ApiClient>(),
  //     localDb: getIt<LocalDatabase>(),
  //     connectivity: getIt<ConnectivityService>(),
  //   ),
  // );

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
}
