import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// ─────────────────────────────────────────────────────────────
///  APPENDIX E — COMPLETE NOTIFICATION CONTENT TABLE
///  All 14 notification types, 9 Android channels, templates.
/// ─────────────────────────────────────────────────────────────

/// Ordered enum for all notification types in the spec.
enum NotificationType {
  incompleteOnboarding,
  dailyWorkout,
  preSleep,
  streakAtRisk,
  streakBroken,
  streakMilestone,
  progressMilestone,
  reEngagement7d,
  reEngagement14d,
  reEngagement30d,
  weeklySummary,
  goalProximity,
  newContent,
  planUpdate,
}

/// Content definition for one notification type (Appendix E).
class NotificationContent {
  final String titleEn;
  final String bodyEn;
  final String channelId;
  final String channelName;
  final String channelDescription;
  final Priority priorityAndroid;
  final Importance importanceAndroid;

  const NotificationContent({
    required this.titleEn,
    required this.bodyEn,
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    required this.priorityAndroid,
    required this.importanceAndroid,
  });

  /// Resolve template variables like `{streak}`, `{cm}`, etc.
  String resolveTitle(Map<String, dynamic> vars) => _resolve(titleEn, vars);
  String resolveBody(Map<String, dynamic> vars) => _resolve(bodyEn, vars);

  static String _resolve(String template, Map<String, dynamic> vars) {
    String result = template;
    for (final entry in vars.entries) {
      result = result.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return result;
  }
}

/// All notification content definitions, keyed by type.
final Map<NotificationType, NotificationContent> notificationContents = {
  NotificationType.incompleteOnboarding: NotificationContent(
    titleEn: 'Complete Your Assessment',
    bodyEn: 'See your height potential — finish your assessment in 2 minutes!',
    channelId: 'onboarding',
    channelName: 'Onboarding',
    channelDescription: 'Reminders to complete your initial profile',
    priorityAndroid: Priority.high,
    importanceAndroid: Importance.high,
  ),
  NotificationType.dailyWorkout: NotificationContent(
    titleEn: 'Hey {name}, Time for Your Workout! 🔥',
    bodyEn: "Don't break your streak! Today's exercises await.",
    channelId: 'workout',
    channelName: 'Workout Reminders',
    channelDescription: 'Daily workout and exercise reminders',
    priorityAndroid: Priority.high,
    importanceAndroid: Importance.high,
  ),
  NotificationType.preSleep: NotificationContent(
    titleEn: 'Wind Down Time 🌙',
    bodyEn: 'HGH peaks during deep sleep. Lights out soon!',
    channelId: 'sleep',
    channelName: 'Sleep Reminders',
    channelDescription: 'Pre-bedtime wind-down reminders',
    priorityAndroid: Priority.defaultPriority,
    importanceAndroid: Importance.defaultImportance,
  ),
  NotificationType.streakAtRisk: NotificationContent(
    titleEn: 'Streak at Risk! ⚠️',
    bodyEn: 'Your {streak}-day streak is at risk! A quick 10-min session keeps it alive.',
    channelId: 'streak',
    channelName: 'Streak Alerts',
    channelDescription: 'Streak warnings, losses, and milestones',
    priorityAndroid: Priority.high,
    importanceAndroid: Importance.high,
  ),
  NotificationType.streakBroken: NotificationContent(
    titleEn: 'Streak Lost 💔',
    bodyEn: "Your streak was broken. Don't worry — start fresh today!",
    channelId: 'streak',
    channelName: 'Streak Alerts',
    channelDescription: 'Streak warnings, losses, and milestones',
    priorityAndroid: Priority.high,
    importanceAndroid: Importance.high,
  ),
  NotificationType.streakMilestone: NotificationContent(
    titleEn: 'Milestone Unlocked! 🏆',
    bodyEn: 'Congrats on your {streak}-day streak, {name}! Keep up the amazing work!',
    channelId: 'streak',
    channelName: 'Streak Alerts',
    channelDescription: 'Streak warnings, losses, and milestones',
    priorityAndroid: Priority.defaultPriority,
    importanceAndroid: Importance.defaultImportance,
  ),
  NotificationType.progressMilestone: NotificationContent(
    titleEn: "You're Growing! 📈",
    bodyEn: 'You\'ve grown {cm} cm since last measurement!',
    channelId: 'progress',
    channelName: 'Progress Updates',
    channelDescription: 'Height milestone achievements',
    priorityAndroid: Priority.high,
    importanceAndroid: Importance.high,
  ),
  NotificationType.reEngagement7d: NotificationContent(
    titleEn: 'We Miss You, {name}! 💪',
    bodyEn: 'Your growth plan is waiting. Every day counts!',
    channelId: 're_engage',
    channelName: 'Re-engagement',
    channelDescription: 'Come-back nudges after inactivity',
    priorityAndroid: Priority.defaultPriority,
    importanceAndroid: Importance.defaultImportance,
  ),
  NotificationType.reEngagement14d: NotificationContent(
    titleEn: 'Still Thinking About Growth?',
    bodyEn: "Don't leave your potential behind, {name}.",
    channelId: 're_engage',
    channelName: 'Re-engagement',
    channelDescription: 'Come-back nudges after inactivity',
    priorityAndroid: Priority.defaultPriority,
    importanceAndroid: Importance.defaultImportance,
  ),
  NotificationType.reEngagement30d: NotificationContent(
    titleEn: 'Your Progress Matters',
    bodyEn: "It's not too late. Height growth is a marathon.",
    channelId: 're_engage',
    channelName: 'Re-engagement',
    channelDescription: 'Come-back nudges after inactivity',
    priorityAndroid: Priority.high,
    importanceAndroid: Importance.high,
  ),
  NotificationType.weeklySummary: NotificationContent(
    titleEn: 'Your Weekly Summary 📊',
    bodyEn: 'This week: {workouts} workouts, {sleep}h sleep, {meals} meals logged.',
    channelId: 'summary',
    channelName: 'Weekly Summary',
    channelDescription: 'Weekly activity summary',
    priorityAndroid: Priority.defaultPriority,
    importanceAndroid: Importance.defaultImportance,
  ),
  NotificationType.goalProximity: NotificationContent(
    titleEn: 'Almost There! 🎯',
    bodyEn: "You're only {cm} cm from your goal! Keep pushing!",
    channelId: 'goal',
    channelName: 'Goal Proximity',
    channelDescription: 'When you are close to your target height',
    priorityAndroid: Priority.high,
    importanceAndroid: Importance.high,
  ),
  NotificationType.newContent: NotificationContent(
    titleEn: 'New Exercise Available',
    bodyEn: 'Check out our latest growth exercise!',
    channelId: 'content',
    channelName: 'New Content',
    channelDescription: 'New exercises and educational content',
    priorityAndroid: Priority.low,
    importanceAndroid: Importance.low,
  ),
  NotificationType.planUpdate: NotificationContent(
    titleEn: 'Plan Updated 📋',
    bodyEn: 'Your growth plan has been updated based on your latest progress.',
    channelId: 'plan',
    channelName: 'Plan Updates',
    channelDescription: 'Plan change notifications',
    priorityAndroid: Priority.defaultPriority,
    importanceAndroid: Importance.defaultImportance,
  ),
};

/// ─────────────────────────────────────────────────────────────
///  NOTIFICATION ID RANGES
///  Each type gets its own range so IDs never collide.
/// ─────────────────────────────────────────────────────────────
const Map<NotificationType, int> _notificationIdBase = {
  NotificationType.incompleteOnboarding: 1000,
  NotificationType.dailyWorkout: 2000,
  NotificationType.preSleep: 3000,
  NotificationType.streakAtRisk: 4000,
  NotificationType.streakBroken: 4001,
  NotificationType.streakMilestone: 4100,
  NotificationType.progressMilestone: 5000,
  NotificationType.reEngagement7d: 6000,
  NotificationType.reEngagement14d: 6001,
  NotificationType.reEngagement30d: 6002,
  NotificationType.weeklySummary: 7000,
  NotificationType.goalProximity: 8000,
  NotificationType.newContent: 9000,
  NotificationType.planUpdate: 10000,
};

/// ─────────────────────────────────────────────────────────────
///  NOTIFICATION SERVICE
/// ─────────────────────────────────────────────────────────────
class NotificationService {
  // ── SharedPreference keys ──
  static const String _keyMasterEnabled = 'notifications_enabled';
  static const String _keyWorkoutHour = 'notification_hour';
  static const String _keyWorkoutMinute = 'notification_minute';
  static const String _keySleepHour = 'notification_sleep_hour';
  static const String _keySleepMinute = 'notification_sleep_minute';
  static const String _keyPerTypeEnabled = 'notif_type_enabled';
  static const String _keyLastActiveDate = 'notif_last_active_date';
  static const String _keySentReEngagement = 'notif_sent_reengage';
  static const String _keyLastStreakMilestone = 'notif_last_streak_milestone';
  static const String _keyPromptShown = 'notif_prompt_shown';
  static const String _keyPromptDismissed = 'notif_prompt_dismissed';
  static const String _keyUserName = 'user_display_name';

  late final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  // ── Init ──

  Future<void> init() async {
    if (_initialized) return;
    _plugin = FlutterLocalNotificationsPlugin();

    // Create all Android notification channels upfront
    final channels = <AndroidNotificationChannel>[
      AndroidNotificationChannel(
        'onboarding', 'Onboarding',
        description: 'Reminders to complete your initial profile',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'workout', 'Workout Reminders',
        description: 'Daily workout and exercise reminders',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'sleep', 'Sleep Reminders',
        description: 'Pre-bedtime wind-down reminders',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        'streak', 'Streak Alerts',
        description: 'Streak warnings, losses, and milestones',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'progress', 'Progress Updates',
        description: 'Height milestone achievements',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        're_engage', 'Re-engagement',
        description: 'Come-back nudges after inactivity',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'summary', 'Weekly Summary',
        description: 'Weekly activity summary',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        'goal', 'Goal Proximity',
        description: 'When you are close to your target height',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'content', 'New Content',
        description: 'New exercises and educational content',
        importance: Importance.low,
      ),
      AndroidNotificationChannel(
        'plan', 'Plan Updates',
        description: 'Plan change notifications',
        importance: Importance.defaultImportance,
      ),
    ];

    // Android notification init with fallback
    try {
      final androidSettings = AndroidInitializationSettings('ic_launcher');
      await _plugin.initialize(
        InitializationSettings(android: androidSettings),
      );
    } catch (e) {
      try {
        await _plugin.initialize(InitializationSettings());
      } catch (e2) {
        print('⚠️ Notification init failed, continuing anyway');
      }
    }

    // Register all Android notification channels after plugin init
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    for (final channel in channels) {
      await androidPlugin?.createNotificationChannel(channel);
    }

    tz_data.initializeTimeZones();
    _initialized = true;
  }

  /// Check if we have notification permission (Android 13+).
  Future<bool> hasPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return true; // non-Android
    return await androidPlugin.areNotificationsEnabled() ?? true;
  }

  /// Request notification permission (Android 13+ shows system dialog).
  Future<bool> requestPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return true; // non-Android — no permission needed
    await androidPlugin.requestNotificationsPermission();
    // Check if granted
    return await androidPlugin.areNotificationsEnabled() ?? false;
  }

  // ── Master toggle ──

  Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMasterEnabled) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMasterEnabled, enabled);
    if (enabled) {
      await _rescheduleAll();
    } else {
      await cancelAll();
    }
  }

  /// Per-type toggle — individual types can be disabled independently.
  Future<bool> isTypeEnabled(NotificationType type) async {
    // If master is off, nothing is enabled
    final master = await isEnabled;
    if (!master) return false;
    // Per-type defaults to true (opt-out)
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPerTypeEnabled);
    if (raw == null) return true;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map[type.name] as bool? ?? true;
  }

  Future<void> setTypeEnabled(NotificationType type, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPerTypeEnabled);
    final map = raw != null
        ? (jsonDecode(raw) as Map<String, dynamic>)
        : <String, dynamic>{};
    map[type.name] = enabled;
    await prefs.setString(_keyPerTypeEnabled, jsonEncode(map));
    // Re-schedule or cancel this type
    if (enabled && await isEnabled) {
      await _scheduleType(type);
    } else {
      await _cancelType(type);
    }
  }

  // ── Workout notification time ──

  Future<Map<String, int>> get notificationTime async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'hour': prefs.getInt(_keyWorkoutHour) ?? 9,
      'minute': prefs.getInt(_keyWorkoutMinute) ?? 0,
    };
  }

  Future<void> setNotificationTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyWorkoutHour, hour);
    await prefs.setInt(_keyWorkoutMinute, minute);
    if (await isEnabled) {
      await _scheduleType(NotificationType.dailyWorkout);
    }
  }

  // ── Sleep notification time ──

  Future<Map<String, int>> get sleepTime async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'hour': prefs.getInt(_keySleepHour) ?? 22,
      'minute': prefs.getInt(_keySleepMinute) ?? 0,
    };
  }

  Future<void> setSleepTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySleepHour, hour);
    await prefs.setInt(_keySleepMinute, minute);
    if (await isEnabled) {
      await _scheduleType(NotificationType.preSleep);
    }
  }

  // ── Activity tracking ──

  /// Mark today as an active day — used for re-engagement and streak checks.
  Future<void> markTodayActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyLastActiveDate,
      DateTime.now().toIso8601String().split('T').first,
    );
    // Clear re-engagement flags — user is back
    await prefs.remove(_keySentReEngagement);
  }

  /// Whether we should show the notification permission prompt.
  Future<bool> shouldShowPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedPermanently = prefs.getBool(_keyPromptDismissed) ?? false;
    final enabled = await isEnabled;
    if (dismissedPermanently || enabled) return false;

    // "Ask Later" stores today's date — only suppress for the rest of today
    final shownDateStr = prefs.getString(_keyPromptShown);
    if (shownDateStr != null) {
      final shownDate = DateTime.tryParse(shownDateStr);
      if (shownDate != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final shownDay = DateTime(shownDate.year, shownDate.month, shownDate.day);
        // Same calendar day → don't re-show. Next day → prompt again.
        if (today == shownDay) return false;
      }
    }

    return true;
  }

  /// Mark that the permission prompt has been shown today ("Ask Later").
  /// Next calendar day, the prompt will show again.
  Future<void> markPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPromptShown, DateTime.now().toIso8601String());
  }

  /// Mark that the user never wants to see the prompt again.
  Future<void> markPromptDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPromptDismissed, true);
  }

  /// Clear prompt state (user changed their mind in settings).
  Future<void> resetPromptState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPromptShown);
    await prefs.remove(_keyPromptDismissed);
  }

  /// Days since the user was last active.
  Future<int> get daysSinceLastActive async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyLastActiveDate);
    if (raw == null) return 999; // never active
    final last = DateTime.tryParse(raw);
    if (last == null) return 999;
    return DateTime.now().difference(last).inDays;
  }

  // ── Schedule all (called after onboarding completes) ──

  Future<void> scheduleAllAfterOnboarding() async {
    if (!await isEnabled) return;
    for (final type in NotificationType.values) {
      await _scheduleType(type);
    }
  }

  Future<void> _rescheduleAll() async {
    for (final type in NotificationType.values) {
      await _scheduleType(type);
    }
  }

  // ── Core scheduling — one method per type ──

  Future<void> _scheduleType(NotificationType type) async {
    if (!await isTypeEnabled(type)) return;

    switch (type) {
      case NotificationType.dailyWorkout:
        await _scheduleDailyWorkout();
      case NotificationType.preSleep:
        await _schedulePreSleep();
      case NotificationType.weeklySummary:
        await _scheduleWeeklySummary();
      case NotificationType.incompleteOnboarding:
        await _scheduleIncompleteOnboarding();
      default:
        // Event-driven types (streak, progress, goal, re-engagement, etc.)
        // are fired at the moment the event occurs, not on a schedule.
        break;
    }
  }

  /// Daily workout at user's chosen time.
  Future<void> _scheduleDailyWorkout() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_keyWorkoutHour) ?? 9;
    final minute = prefs.getInt(_keyWorkoutMinute) ?? 0;
    final content = notificationContents[NotificationType.dailyWorkout]!;
    final id = _notificationIdBase[NotificationType.dailyWorkout]!;

    await _cancelById(id);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final vars = await _baseVars;
    await _plugin.zonedSchedule(
      id,
      content.resolveTitle(vars),
      content.resolveBody(vars),
      scheduled,
      _details(content.channelId, content.priorityAndroid),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Pre-sleep at user's chosen bedtime (default 22:00).
  Future<void> _schedulePreSleep() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_keySleepHour) ?? 22;
    final minute = prefs.getInt(_keySleepMinute) ?? 0;
    final content = notificationContents[NotificationType.preSleep]!;
    final id = _notificationIdBase[NotificationType.preSleep]!;

    await _cancelById(id);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      content.titleEn,
      content.bodyEn,
      scheduled,
      _details(content.channelId, content.priorityAndroid),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Weekly summary every Sunday at 10:00.
  Future<void> _scheduleWeeklySummary() async {
    final content = notificationContents[NotificationType.weeklySummary]!;
    final id = _notificationIdBase[NotificationType.weeklySummary]!;

    await _cancelById(id);

    final now = tz.TZDateTime.now(tz.local);
    // Next Sunday at 10:00
    var scheduled = _nextWeekday(tz.local, DateTime.sunday, 10, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    await _plugin.zonedSchedule(
      id,
      content.titleEn,
      content.bodyEn,
      scheduled,
      _details(content.channelId, content.priorityAndroid),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// One-time incomplete onboarding reminder (2 hours after first launch).
  Future<void> _scheduleIncompleteOnboarding() async {
    final content = notificationContents[NotificationType.incompleteOnboarding]!;
    final id = _notificationIdBase[NotificationType.incompleteOnboarding]!;

    await _cancelById(id);

    // Schedule 2 hours from now — only fires if onboarding not completed
    final scheduled = tz.TZDateTime.now(tz.local).add(const Duration(hours: 2));

    await _plugin.zonedSchedule(
      id,
      content.titleEn,
      content.bodyEn,
      scheduled,
      _details(content.channelId, content.priorityAndroid),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Event-driven notifications (fire immediately) ──

  /// Fire when streak is at risk (e.g., end of day, not yet worked out).
  Future<void> fireStreakAtRisk(int currentStreak) async {
    if (!await isTypeEnabled(NotificationType.streakAtRisk)) return;
    if (await wasRecentlyShown(NotificationType.streakAtRisk, withinHours: 4)) return;
    final content = notificationContents[NotificationType.streakAtRisk]!;
    await _plugin.show(
      _notificationIdBase[NotificationType.streakAtRisk]!,
      content.resolveTitle({'streak': currentStreak}),
      content.resolveBody({'streak': currentStreak}),
      _details(content.channelId, content.priorityAndroid),
    );
    await _markShown(NotificationType.streakAtRisk);
  }

  /// Fire when streak is broken.
  Future<void> fireStreakBroken() async {
    if (!await isTypeEnabled(NotificationType.streakBroken)) return;
    final content = notificationContents[NotificationType.streakBroken]!;
    await _plugin.show(
      _notificationIdBase[NotificationType.streakBroken]!,
      content.titleEn,
      content.bodyEn,
      _details(content.channelId, content.priorityAndroid),
    );
  }

  /// Fire when a streak milestone is hit (3, 7, 14, 21, 30, 60, 90).
  Future<void> fireStreakMilestone(int streak) async {
    if (!await isTypeEnabled(NotificationType.streakMilestone)) return;
    // Only fire once per milestone
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_keyLastStreakMilestone) ?? 0;
    if (streak <= last) return;
    await prefs.setInt(_keyLastStreakMilestone, streak);

    final content = notificationContents[NotificationType.streakMilestone]!;
    final vars = await _baseVars;
    await _plugin.show(
      _notificationIdBase[NotificationType.streakMilestone]! + streak,
      content.resolveTitle({...vars, 'streak': streak}),
      content.resolveBody({...vars, 'streak': streak}),
      _details(content.channelId, content.priorityAndroid),
    );
  }

  /// Fire when user logs a new height measurement showing growth.
  Future<void> fireProgressMilestone(double cmGrown) async {
    if (!await isTypeEnabled(NotificationType.progressMilestone)) return;
    if (cmGrown <= 0) return;
    final content = notificationContents[NotificationType.progressMilestone]!;
    await _plugin.show(
      _notificationIdBase[NotificationType.progressMilestone]!,
      content.titleEn,
      content.resolveBody({'cm': cmGrown.toStringAsFixed(1)}),
      _details(content.channelId, content.priorityAndroid),
    );
  }

  /// Fire when user is close to their target height.
  Future<void> fireGoalProximity(double cmRemaining) async {
    if (!await isTypeEnabled(NotificationType.goalProximity)) return;
    if (cmRemaining > 5) return; // Only when within 5 cm
    final content = notificationContents[NotificationType.goalProximity]!;
    await _plugin.show(
      _notificationIdBase[NotificationType.goalProximity]!,
      content.titleEn,
      content.resolveBody({'cm': cmRemaining.toStringAsFixed(1)}),
      _details(content.channelId, content.priorityAndroid),
    );
  }

  /// Fire weekly summary (can be called from scheduler or manual trigger).
  Future<void> fireWeeklySummary({
    int workouts = 0,
    double sleepHours = 0,
    int meals = 0,
  }) async {
    if (!await isTypeEnabled(NotificationType.weeklySummary)) return;
    final content = notificationContents[NotificationType.weeklySummary]!;
    await _plugin.show(
      _notificationIdBase[NotificationType.weeklySummary]!,
      content.titleEn,
      content.resolveBody({
        'workouts': workouts,
        'sleep': sleepHours.toStringAsFixed(0),
        'meals': meals,
      }),
      _details(content.channelId, content.priorityAndroid),
    );
  }

  /// Fire re-engagement notification at the appropriate tier.
  Future<void> fireReEngagement() async {
    final days = await daysSinceLastActive;
    NotificationType type;
    if (days >= 30) {
      type = NotificationType.reEngagement30d;
    } else if (days >= 14) {
      type = NotificationType.reEngagement14d;
    } else if (days >= 7) {
      type = NotificationType.reEngagement7d;
    } else {
      return; // Not yet due
    }

    if (!await isTypeEnabled(type)) return;

    // Only fire once per re-engagement tier
    final prefs = await SharedPreferences.getInstance();
    final sent = prefs.getStringList(_keySentReEngagement) ?? [];
    if (sent.contains(type.name)) return;
    sent.add(type.name);
    await prefs.setStringList(_keySentReEngagement, sent);

    final content = notificationContents[type]!;
    final vars = await _baseVars;
    await _plugin.show(
      _notificationIdBase[type]!,
      content.resolveTitle(vars),
      content.resolveBody(vars),
      _details(content.channelId, content.priorityAndroid),
    );
  }

  /// Send a test notification to confirm the system is working.
  Future<void> sendTestNotification() async {
    final vars = await _baseVars;
    final name = vars['name'] as String? ?? '';
    final greeting = name.isNotEmpty && name != 'there' ? name : 'there';

    await _plugin.show(
      9999, // unique test ID
      'Notifications are ON! 🔔',
      'You\'ll now get workout reminders, streak alerts, bedtime nudges, and weekly summaries, $greeting.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'workout', 'Workout Reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('ic_launcher'),
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Fire a plan update notification.
  Future<void> firePlanUpdate() async {
    if (!await isTypeEnabled(NotificationType.planUpdate)) return;
    final content = notificationContents[NotificationType.planUpdate]!;
    await _plugin.show(
      _notificationIdBase[NotificationType.planUpdate]!,
      content.titleEn,
      content.bodyEn,
      _details(content.channelId, content.priorityAndroid),
    );
  }

  /// Fire new content notification.
  Future<void> fireNewContent() async {
    if (!await isTypeEnabled(NotificationType.newContent)) return;
    final content = notificationContents[NotificationType.newContent]!;
    await _plugin.show(
      _notificationIdBase[NotificationType.newContent]!,
      content.titleEn,
      content.bodyEn,
      _details(content.channelId, content.priorityAndroid),
    );
  }

  // ── Cancel helpers ──

  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  Future<void> _cancelById(int id) async {
    if (!_initialized) return;
    await _plugin.cancel(id);
  }

  Future<void> _cancelType(NotificationType type) async {
    // Some types have fixed IDs, others have ranges — cancel the base
    await _cancelById(_notificationIdBase[type]!);
    // Also cancel the streak milestone range (base + streak number)
    if (type == NotificationType.streakMilestone) {
      for (int i = 3; i <= 90; i++) {
        await _cancelById(_notificationIdBase[type]! + i);
      }
    }
  }

  // ── Helpers ──

  NotificationDetails _details(String channelId, Priority priority) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelId, // name — already registered at init
        channelDescription: '',
        importance: Importance.values.firstWhere(
          (i) => i.name == priority.name,
          orElse: () => Importance.defaultImportance,
        ),
        priority: priority,
          icon: 'ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('ic_launcher'),
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  /// Get the next occurrence of [weekday] at [hour]:[minute].
  static tz.TZDateTime _nextWeekday(
    tz.Location loc,
    int weekday, // DateTime.sunday = 7, etc.
    int hour,
    int minute,
  ) {
    var d = tz.TZDateTime(loc, DateTime.now().year, DateTime.now().month, DateTime.now().day, hour, minute);
    while (d.weekday != weekday) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  /// Check if a specific notification ID has been shown recently (within [hours]).
  /// Uses SharedPreferences to store last-shown timestamps.
  Future<bool> wasRecentlyShown(NotificationType type, {int withinHours = 24}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'notif_last_shown_${type.name}';
    final lastStr = prefs.getString(key);
    if (lastStr == null) return false;
    final last = DateTime.tryParse(lastStr);
    if (last == null) return false;
    return DateTime.now().difference(last).inHours < withinHours;
  }

  Future<void> _markShown(NotificationType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'notif_last_shown_${type.name}',
      DateTime.now().toIso8601String(),
    );
  }

  /// Read the user's display name from SharedPreferences.
  Future<String> get _userName async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName) ?? '';
  }

  /// Base variable map — every notification gets these.
  Future<Map<String, dynamic>> get _baseVars async {
    final name = await _userName;
    return {
      'name': name.isNotEmpty ? name : 'there',
    };
  }
}

// ── Riverpod Provider ──

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
