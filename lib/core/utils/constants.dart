/// Core constants and configuration for the GetTaller app.
class AppConstants {
  AppConstants._();

  // ── App Info ──
  static const String appName = 'GetTaller';
  static const String packageName = 'com.gettaller.app';
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
  // Using Google test IDs until AdMob account is approved
  // Once approved, switch to production IDs below:
  //   Banner:   ca-app-pub-1626231124946252/8650924867
  //   Inter:    ca-app-pub-1626231124946252/6094832720
  //   Rewarded: ca-app-pub-1626231124946252/7345546664
  //   Native:   ca-app-pub-1626231124946252/3963493400
  //   App ID:   ca-app-pub-1626231124946252~5312234093
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String nativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';

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
