import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/app_config.dart';
import 'core/utils/environment.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Core App & Services
  // Use AppEnvironment.mock to test UI flows without backend/CORS issues
  await AppConfig.init(environment: AppEnvironment.mock);

  // Initialize Service Placeholders
  final firebaseService = FirebaseService();
  await firebaseService.initialize();

  runApp(
    const ProviderScope(
      child: LiveRestroSalesApp(),
    ),
  );
}
