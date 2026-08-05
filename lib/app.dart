import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'shared/widgets/connectivity_gate.dart';

/// Root widget for the GetTaller app.
class GetTallerApp extends ConsumerWidget {
  const GetTallerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'GetTaller',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      // Ensure scrollable behavior works correctly across all devices
      scrollBehavior: const MaterialScrollBehavior(),
      builder: (context, child) {
        // Prevent Samsung's extreme text scaling from causing overflow errors
        // and apparent zoom by clamping the system text scaler. (The device
        // pixel ratio and density are handled natively on Android in
        // MainActivity — forcing them here is a no-op, since copyWith with the
        // same values changes nothing.)
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
