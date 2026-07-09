import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/services/hive_service.dart';
import 'core/services/user_data_service.dart';
import 'core/services/ai_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // CRITICAL: Only await Firebase + Hive (fast, needed immediately)
  try {
    await Firebase.initializeApp();
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  await HiveService.init();

  // SHOW THE APP IMMEDIATELY — no waiting for non-critical services
  final notifService = NotificationService();
  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(notifService),
      ],
      child: const GetTallerApp(),
    ),
  );

  // Fire-and-forget: init everything else in background AFTER app renders
  _initBackgroundServices(notifService);
}

Future<void> _initBackgroundServices(NotificationService notifService) async {
  try {
    await UserDataService().migrateLegacyDataIfNeeded();
  } catch (_) {}
  try {
    await AiService().initialize();
  } catch (_) {}
  try {
    await notifService.init();
  } catch (_) {}
  try {
    await MobileAds.instance.initialize();
  } catch (_) {}
}
