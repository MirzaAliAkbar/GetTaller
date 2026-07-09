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
  debugPrint('🚀 GetTaller - Starting app initialization');
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('✅ Widgets binding initialized');

  // Initialize Firebase and Crashlytics
  try {
    debugPrint('🔥 Initializing Firebase...');
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized');

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Pass all uncaught errors from the framework to Crashlytics.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  } catch (e) {
    debugPrint('❌ Firebase init failed: $e. Crashlytics will not be available.');
  }

  try {
    debugPrint('💾 Initializing Hive storage...');
    await HiveService.init();
    debugPrint('✅ Hive initialized');
  } catch (e) {
    debugPrint('❌ Hive init failed: $e');
    rethrow;
  }

  try {
    debugPrint('📊 Migrating user data...');
    // Migrate any legacy SharedPreferences data into Hive before first use.
    await UserDataService().migrateLegacyDataIfNeeded();
    debugPrint('✅ User data migrated');
  } catch (e) {
    debugPrint('❌ User data migration failed: $e');
  }

  // Initialize AI Service with API key (from Remote Config or build-time)
  try {
    debugPrint('🤖 Initializing AI Service...');
    await AiService().initialize();
    debugPrint('✅ AI Service initialized');
  } catch (e) {
    debugPrint('❌ AI Service init failed: $e');
  }

  try {
    debugPrint('🔔 Initializing notifications...');
    final notifService = NotificationService();
    await notifService.init();
    debugPrint('✅ Notifications initialized');

    try {
      debugPrint('📱 Initializing AdMob...');
      await MobileAds.instance.initialize();
      debugPrint('✅ AdMob initialized');
    } catch (e) {
      debugPrint('❌ AdMob init failed: $e');
    }

    debugPrint('🎨 Starting app...');
    runApp(
      ProviderScope(
        overrides: [
          notificationServiceProvider.overrideWithValue(notifService),
        ],
        child: const GetTallerApp(),
      ),
    );
  } catch (e) {
    debugPrint('❌ Fatal error during initialization: $e');
    rethrow;
  }
}
