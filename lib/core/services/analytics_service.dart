import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;
  AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get analyticsObserver =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  Future<void> logOnboardingStep(int step, String screenName) async {
    await _analytics.logEvent(
      name: 'onboarding_step',
      parameters: {
        'step_number': step,
        'screen_name': screenName,
      },
    );
  }

  Future<void> logOnboardingCompleted() async {
    await _analytics.logEvent(name: 'onboarding_completed');
  }

  Future<void> logWorkoutStarted(int levelNumber) async {
    await _analytics.logEvent(
      name: 'workout_started',
      parameters: {'level_number': levelNumber},
    );
  }

  Future<void> logWorkoutCompleted(int levelNumber) async {
    await _analytics.logEvent(
      name: 'workout_completed',
      parameters: {'level_number': levelNumber},
    );
  }

  Future<void> logAiCoachMessageSent() async {
    await _analytics.logEvent(name: 'ai_coach_message_sent');
  }

  Future<void> logAdImpression(String adUnitId) async {
    await _analytics.logEvent(
      name: 'ad_impression',
      parameters: {'ad_unit_id': adUnitId},
    );
  }

  Future<void> logAdClicked(String adUnitId) async {
    await _analytics.logEvent(
      name: 'ad_clicked',
      parameters: {'ad_unit_id': adUnitId},
    );
  }

  Future<void> logMealLogged() async {
    await _analytics.logEvent(name: 'meal_logged');
  }

  Future<void> logSleepLogged() async {
    await _analytics.logEvent(name: 'sleep_logged');
  }

  Future<void> logHeightMeasured() async {
    await _analytics.logEvent(name: 'height_measured');
  }

  Future<void> logShareUsed(String contentType) async {
    await _analytics.logEvent(
      name: 'share_used',
      parameters: {'content_type': contentType},
    );
  }

  Future<void> logSettingChanged(String settingName, dynamic value) async {
    await _analytics.logEvent(
      name: 'setting_changed',
      parameters: {
        'setting_name': settingName,
        'value': value.toString(),
      },
    );
  }

  Future<void> logError(String errorType, String screen) async {
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'screen': screen,
      },
    );
  }
}
