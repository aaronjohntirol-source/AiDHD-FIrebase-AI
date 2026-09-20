import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    providerWeb: kIsWeb ? WebDebugProvider() : null,
    providerAndroid: const AndroidDebugProvider(),
    providerWindows: const WindowsDebugProvider(
      debugToken: String.fromEnvironment('APP_CHECK_DEBUG_TOKEN'),
    ),
  );

  final provider = AppProvider();
  await provider.init(); // Load accessibility settings from storage

  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: const AidhdApp(),
    ),
  );
}
