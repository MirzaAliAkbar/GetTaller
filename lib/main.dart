import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
