import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/services/subscription_service.dart';
import 'shared/widgets/connectivity_gate.dart';

/// Root widget for the GetTaller app.
/// Monitors app lifecycle to re-verify subscription on every foreground.
class GetTallerApp extends ConsumerStatefulWidget {
  const GetTallerApp({super.key});

  @override
  ConsumerState<GetTallerApp> createState() => _GetTallerAppState();
}

class _GetTallerAppState extends ConsumerState<GetTallerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-verify subscription every time the app comes to foreground.
  /// This catches passive expiry (subscription ended while app was closed).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Restore purchases to check if subscription is still active.
      // If expired, the service will revoke premium.
      SubscriptionService().restorePurchases();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'GetTaller',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      scrollBehavior: const MaterialScrollBehavior(),
      builder: (context, child) {
        final MediaQueryData mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(minScaleFactor: 0.8, maxScaleFactor: 1.3),
          ),
          child: ConnectivityGate(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
