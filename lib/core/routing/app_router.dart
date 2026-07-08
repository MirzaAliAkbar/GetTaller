import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/analytics_service.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/welcome_screen.dart';
import '../../features/onboarding/presentation/screens/privacy_shield_screen.dart';
import '../../features/onboarding/presentation/screens/gender_selection_screen.dart';
import '../../features/onboarding/presentation/screens/birth_date_screen.dart';
import '../../features/onboarding/presentation/screens/current_measurements_screen.dart';
import '../../features/onboarding/presentation/screens/parent_height_screen.dart';
import '../../features/onboarding/presentation/screens/sports_selection_screen.dart';
import '../../features/onboarding/presentation/screens/sleep_duration_screen.dart';
import '../../features/onboarding/presentation/screens/analysis_depth_screen.dart';
import '../../features/onboarding/presentation/screens/analyzing_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_insight_screen.dart';
import '../../features/onboarding/presentation/screens/result_preview_screen.dart';
import '../../features/onboarding/presentation/screens/your_plan_screen.dart';
import '../../features/dashboard/presentation/screens/main_navigation_screen.dart';
import '../../features/exercises/presentation/screens/workout_player_screen.dart';
import '../../features/education/presentation/screens/education_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/ar_height/presentation/screens/ar_height_measure_screen.dart';
import '../../features/daily_plan/presentation/screens/plan_complete_screen.dart';
import '../../features/daily_plan/presentation/screens/weekly_recap_screen.dart';

/// GoRouter configuration — Blueprint §1.2
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    observers: [
      AnalyticsService().analyticsObserver,
    ],
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Onboarding (14 steps) — Blueprint §3.1 ──
      GoRoute(
        path: '/onboarding/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding/privacy',
        name: 'privacyShield',
        builder: (context, state) => const PrivacyShieldScreen(),
      ),
      GoRoute(
        path: '/onboarding/gender',
        name: 'gender',
        builder: (context, state) => const GenderSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding/birth-date',
        name: 'birthDate',
        builder: (context, state) => const BirthDateScreen(),
      ),
      GoRoute(
        path: '/onboarding/measurements',
        name: 'measurements',
        builder: (context, state) => const CurrentMeasurementsScreen(),
      ),
      GoRoute(
        path: '/onboarding/parent-height',
        name: 'parentHeight',
        builder: (context, state) => const ParentHeightScreen(),
      ),
      GoRoute(
        path: '/onboarding/sports',
        name: 'sports',
        builder: (context, state) => const SportsSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding/sleep',
        name: 'sleep',
        builder: (context, state) => const SleepDurationScreen(),
      ),
      GoRoute(
        path: '/onboarding/analysis-depth',
        name: 'analysisDepth',
        builder: (context, state) => const AnalysisDepthScreen(),
      ),
      GoRoute(
        path: '/onboarding/analyzing',
        name: 'analyzing',
        builder: (context, state) => const AnalyzingScreen(),
      ),
      GoRoute(
        path: '/onboarding/insight',
        name: 'insight',
        builder: (context, state) => const OnboardingInsightScreen(),
      ),
      GoRoute(
        path: '/onboarding/result-preview',
        name: 'resultPreview',
        builder: (context, state) => const ResultPreviewScreen(),
      ),
      GoRoute(
        path: '/onboarding/your-plan',
        name: 'yourPlan',
        builder: (context, state) => const YourPlanScreen(),
      ),

      // ── Main App (Post-Onboarding) ──
      GoRoute(
        path: '/main',
        name: 'main',
        builder: (context, state) => const MainNavigationScreen(),
      ),

      // ── Feature Screens ──
      GoRoute(
        path: '/workout',
        name: 'workoutPlayer',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            final ids = (extra['ids'] as List<dynamic>?)?.cast<String>() ?? [];
            final level = extra['level'] as int?;
            return WorkoutPlayerScreen(exerciseIds: ids, levelNumber: level);
          }
          final ids = extra as List<String>? ?? [];
          return WorkoutPlayerScreen(exerciseIds: ids);
        },
      ),
      GoRoute(
        path: '/education',
        name: 'education',
        builder: (context, state) => const EducationScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/ar-measure',
        name: 'arMeasure',
        builder: (context, state) => const ARHeightMeasureScreen(),
      ),
      GoRoute(
        path: '/plan-complete',
        name: 'planComplete',
        builder: (context, state) => const PlanCompleteScreen(),
      ),
      GoRoute(
        path: '/weekly-recap',
        name: 'weeklyRecap',
        builder: (context, state) => const WeeklyRecapScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Page not found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/main'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
