import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'app.dart';
import 'core/ads/ad_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/hive_service.dart';
import 'core/services/user_data_service.dart';
import 'core/services/ai_service.dart';
import 'core/services/attribution_service.dart';
import 'core/utils/unit_converter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // CRITICAL: Only await Firebase + Hive + UnitConverter (fast, needed immediately)
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
  await UnitConverter.init();

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
    // Gathers UMP (GDPR/US-states) consent and, on iOS, requests App
    // Tracking Transparency authorization *before* the Google Mobile
    // Ads SDK — and its AppLovin/Unity mediation adapters — initialize.
    // Skipping this or reordering it risks partners being blocked from
    // serving to EEA/UK/US users and lower iOS fill/eCPM.
    await AdService().initializeWithConsent();
    // Load cached referral code for ad attribution
    await AdService().initAttribution();
  } catch (_) {}

  // Initialize attribution service (install ID, referral code cache)
  try {
    await AttributionService().initialize();
  } catch (_) {}

  // Daily retention ping — only for referred users (fire-and-forget)
  if (AttributionService().hasReferralCode) {
    try {
      await AttributionService().logDailyPing();
    } catch (_) {}
  }
}
