import '../core/di/service_locator.dart';
import '../core/storage/hive_storage_service.dart';
import '../core/utils/environment.dart';
import '../core/utils/logging/app_logger.dart';

/// App Global Initialization & Configuration Handler.
class AppConfig {
  AppConfig._();

  static Future<void> init({AppEnvironment environment = AppEnvironment.dev}) async {
    Environment.setEnvironment(environment);
    AppLogger.i('🚀 [AppConfig] Initializing LiveRestro Sales in ${environment.name.toUpperCase()} mode...');

    // Initialize local storage engines
    await HiveStorageService.init();

    // Initialize GetIt Service Locator Dependency Injection
    await setupServiceLocator();
  }
}
