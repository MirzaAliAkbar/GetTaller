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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and Crashlytics
  try {
    await Firebase.initializeApp();
    
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    
    // Pass all uncaught errors from the framework to Crashlytics.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  } catch (e) {
    debugPrint('Firebase init failed: $e. Crashlytics will not be available.');
  }

  await HiveService.init();
  // Migrate any legacy SharedPreferences data into Hive before first use.
  await UserDataService().migrateLegacyDataIfNeeded();

  final notifService = NotificationService();
  await notifService.init();

  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    debugPrint('AdMob init failed: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(notifService),
      ],
      child: const GetTallerApp(),
    ),
  );
}
