import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../network/api_client.dart';
import '../network/network_manager.dart';
import '../network/token_manager.dart';
import '../security/security_manager.dart';
import '../storage/secure_storage_service.dart';
import '../storage/hive_storage_service.dart';
import '../storage/sqflite_storage_service.dart';
import '../storage/pending_request_queue.dart';
import '../storage/offline_sync_manager.dart';
import '../utils/image_picker_helper.dart';
import '../../services/connectivity_service.dart';
import '../../services/biometric_service.dart';
import '../../services/firebase_service.dart';
import '../../services/google_maps_service.dart';
import '../../services/sms_gateway_service.dart';
import '../../features/orders/domain/repositories/order_repository.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/data/repositories/mock_profile_repository.dart';
import '../../shared/data/datasources/auth_local_datasource.dart';
import '../../shared/data/datasources/auth_remote_datasource.dart';
import '../../shared/data/repositories/auth_repository_impl.dart';
import '../../shared/data/repositories/mock_auth_repository.dart';
import '../../shared/domain/repositories/auth_repository.dart';
import '../utils/environment.dart';

final getIt = GetIt.instance;

/// Centralized GetIt Service Locator Dependency Injection initializer.
Future<void> setupServiceLocator() async {
  // 1. External Third-party Singletons
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  );
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());
  getIt.registerLazySingleton<LocalAuthentication>(() => LocalAuthentication());
  getIt.registerLazySingleton<ImagePicker>(() => ImagePicker());

  // 2. Core Storage Engine Singletons
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(getIt<FlutterSecureStorage>()),
  );
  getIt.registerLazySingleton<HiveStorageService>(() => HiveStorageService());
  getIt.registerLazySingleton<SqfliteStorageService>(() => SqfliteStorageService());

  // 3. Network & Security Managers
  getIt.registerLazySingleton<TokenManager>(
    () => TokenManager(getIt<SecureStorageService>()),
  );
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(getIt<TokenManager>()),
  );
  getIt.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(getIt<Connectivity>()),
  );
  getIt.registerLazySingleton<NetworkManager>(
    () => NetworkManager(getIt<ConnectivityService>()),
  );
  getIt.registerLazySingleton<BiometricService>(
    () => BiometricService(getIt<LocalAuthentication>()),
  );
  getIt.registerLazySingleton<SecurityManager>(
    () => SecurityManager(getIt<SecureStorageService>(), getIt<BiometricService>()),
  );

  // 4. Offline Persistence & Sync Queue
  getIt.registerLazySingleton<PendingRequestQueue>(
    () => PendingRequestQueue(getIt<SqfliteStorageService>()),
  );
  getIt.registerLazySingleton<OfflineSyncManager>(
    () => OfflineSyncManager(getIt<PendingRequestQueue>(), getIt<NetworkManager>()),
  );

  // 5. Utilities & Integration Services
  getIt.registerLazySingleton<ImagePickerHelper>(
    () => ImagePickerHelper(getIt<ImagePicker>()),
  );
  getIt.registerLazySingleton<FirebaseService>(() => FirebaseService());
  getIt.registerLazySingleton<GoogleMapsService>(() => GoogleMapsService());
  getIt.registerLazySingleton<SmsGatewayService>(() => SmsGatewayService());

  // 6. DataSources & Clean Architecture Repositories
  getIt.registerLazySingleton<OrderRepository>(() => OrderRepository());
  getIt.registerLazySingleton<ProfileRepository>(
    () {
      if (Environment.isMock) {
        return MockProfileRepository();
      }
      return ProfileRepositoryImpl(getIt<ApiClient>());
    },
  );
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSource(getIt<SecureStorageService>(), getIt<TokenManager>()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => Environment.isMock
        ? MockAuthRepository()
        : AuthRepositoryImpl(getIt<AuthRemoteDataSource>(), getIt<AuthLocalDataSource>()),
  );
}
