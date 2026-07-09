/// Core constants and configuration for the GetTaller app.
class AppConstants {
  AppConstants._();

  // ── App Info ──
  static const String appName = 'GetTaller';
  static const String packageName = 'com.grayonix.GetTaller';
  static const int appVersion = 1;
  static const String appVersionName = '1.0.0';

  // ── Design (Mobile App UI/UX Skill) ──
  // 8-Point Grid System
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 24;
  static const double spacingXxl = 32;
  static const double spacingSection = 48;
  static const double spacingSectionLg = 80;
  static const double spacingSectionXl = 96;

  // Border radius
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusXxl = 32;

  // Typography
  static const double textXs = 12;
  static const double textSm = 14;
  static const double textMd = 16;
  static const double textLg = 18;
  static const double textXl = 20;
  static const double textXxl = 24;
  static const double textDisplay = 32;
  static const double textHero = 40;

  // Touch targets
  static const double minTouchTarget = 44;

  // ── Ad Placements (Blueprint §3.3) ──
  // Production AdMob IDs for GetTaller app
  // App ID: ca-app-pub-7643307621517317~4891446164

  // Banner Ads
  static const String bannerAdUnitId = 'ca-app-pub-7643307621517317/6942894431'; // Daily Plan
  static const String bannerResultPreviewAdUnitId = 'ca-app-pub-7643307621517317/1529986898'; // Result Preview

  // Interstitial Ads
  static const String interstitialAdUnitId =
      'ca-app-pub-7643307621517317/7896084698'; // Your Plan (onboarding completion)
  static const String interstitialAnalysisAdUnitId =
      'ca-app-pub-7643307621517317/2643758014'; // Analysis Screen

  // Rewarded & Native
  static const String rewardedAdUnitId =
      'ca-app-pub-7643307621517317/1863781970';
  static const String nativeAdUnitId = 'ca-app-pub-7643307621517317/7265529308';

  static const int rewardedVideoGrantCount = 3;
  static const int initialFreeAiQueries = 3;

  // ── Storage ──
  static const String prefOnboardingComplete = 'onboarding_complete';
  static const String prefAiQueriesRemaining = 'ai_queries_remaining';
  static const String prefUnitSystem = 'unit_system';
  static const String prefLanguage = 'language';
  static const String prefTheme = 'theme_mode';
  static const String dbName = 'gettaller.db';

  // ── Height Calculation ──
  static const double avgMaleHeightCm = 174.0;
  static const double avgFemaleHeightCm = 161.0;
  static const int maleGrowthClosureAge = 21;
  static const int femaleGrowthClosureAge = 18;
  static const double tannerConstant = 13.0;
  static const double bmiOptimalMin = 18.5;
  static const double bmiOptimalMax = 24.9;
  static const double minSleepHours = 7;
  static const double optimalSleepHours = 9;

  // ── Exercise ──
  static const int planTotalDays = 90;
  static const int exercisesPerDay = 5;
}
