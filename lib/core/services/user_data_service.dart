import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hive_service.dart';

/// Persisted user data model — saved to SharedPreferences as JSON.
class PersistedUserData {
  final String? name;
  final String gender; // 'male' | 'female'
  final int birthYear;
  final int birthMonth;
  final double currentHeightCm;
  final double currentWeightKg;
  final double fatherHeightCm;
  final double motherHeightCm;
  final String activityLevel; // 'sedentary' | 'moderate' | 'active'
  final double averageSleepHours;
  final String analysisDepth;
  final double? targetHeightCm;
  final int activityDaysPerWeek;
  final String? referralCode;

  PersistedUserData({
    this.name,
    required this.gender,
    required this.birthYear,
    this.birthMonth = 1,
    required this.currentHeightCm,
    required this.currentWeightKg,
    required this.fatherHeightCm,
    required this.motherHeightCm,
    this.activityLevel = 'moderate',
    this.averageSleepHours = 7,
    this.analysisDepth = 'accurate',
    this.targetHeightCm,
    this.activityDaysPerWeek = 3,
    this.referralCode,
  });

  int get ageYears {
    final now = DateTime.now();
    return now.year - birthYear;
  }

  bool get isMale => gender == 'male';

  Map<String, dynamic> toJson() => {
        'name': name,
        'gender': gender,
        'birthYear': birthYear,
        'birthMonth': birthMonth,
        'currentHeightCm': currentHeightCm,
        'currentWeightKg': currentWeightKg,
        'fatherHeightCm': fatherHeightCm,
        'motherHeightCm': motherHeightCm,
        'activityLevel': activityLevel,
        'averageSleepHours': averageSleepHours,
        'analysisDepth': analysisDepth,
        'targetHeightCm': targetHeightCm,
        'activityDaysPerWeek': activityDaysPerWeek,
        if (referralCode != null) 'referralCode': referralCode,
      };

  factory PersistedUserData.fromJson(Map<String, dynamic> json) =>
      PersistedUserData(
        name: json['name'] as String?,
        gender: json['gender'] as String? ?? 'male',
        birthYear: json['birthYear'] as int? ?? 2005,
        birthMonth: json['birthMonth'] as int? ?? 1,
        currentHeightCm: (json['currentHeightCm'] as num?)?.toDouble() ?? 160,
        currentWeightKg: (json['currentWeightKg'] as num?)?.toDouble() ?? 55,
        fatherHeightCm: (json['fatherHeightCm'] as num?)?.toDouble() ?? 175,
        motherHeightCm: (json['motherHeightCm'] as num?)?.toDouble() ?? 162,
        activityLevel: json['activityLevel'] as String? ?? 'moderate',
        averageSleepHours: (json['averageSleepHours'] as num?)?.toDouble() ?? 7,
        analysisDepth: json['analysisDepth'] as String? ?? 'accurate',
        targetHeightCm: (json['targetHeightCm'] as num?)?.toDouble(),
        activityDaysPerWeek: json['activityDaysPerWeek'] as int? ?? 3,
        referralCode: json['referralCode'] as String?,
      );
}

/// A single height measurement entry.
class HeightEntry {
  final DateTime date;
  final double heightCm;

  HeightEntry({required this.date, required this.heightCm});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String().split('T').first,
        'heightCm': heightCm,
      };

  factory HeightEntry.fromJson(Map<String, dynamic> json) => HeightEntry(
        date: DateTime.parse(json['date'] as String),
        heightCm: (json['heightCm'] as num).toDouble(),
      );
}

/// A logged meal entry.
class MealEntry {
  final DateTime date;
  final String description;
  final int calories;
  final double protein;
  final double calcium;

  MealEntry({
    required this.date,
    required this.description,
    required this.calories,
    required this.protein,
    required this.calcium,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String().split('T').first,
        'description': description,
        'calories': calories,
        'protein': protein,
        'calcium': calcium,
      };

  factory MealEntry.fromJson(Map<String, dynamic> json) => MealEntry(
        date: DateTime.parse(json['date'] as String),
        description: json['description'] as String? ?? '',
        calories: json['calories'] as int? ?? 0,
        protein: (json['protein'] as num?)?.toDouble() ?? 0,
        calcium: (json['calcium'] as num?)?.toDouble() ?? 0,
      );
}

/// A single sleep segment (bed → wake).
class SleepSegment {
  final String bedTime; // "HH:MM" format
  final String wakeTime; // "HH:MM" format
  final double hours;

  SleepSegment({
    required this.bedTime,
    required this.wakeTime,
    required this.hours,
  });

  Map<String, dynamic> toJson() => {
        'bedTime': bedTime,
        'wakeTime': wakeTime,
        'hours': hours,
      };

  factory SleepSegment.fromJson(Map<String, dynamic> json) => SleepSegment(
        bedTime: json['bedTime'] as String? ?? '22:00',
        wakeTime: json['wakeTime'] as String? ?? '06:00',
        hours: (json['hours'] as num?)?.toDouble() ?? 8,
      );

  /// Calculate hours from bed/wake times.
  static double calculateHours(String bedTime, String wakeTime) {
    final bedParts = bedTime.split(':');
    final wakeParts = wakeTime.split(':');
    if (bedParts.length != 2 || wakeParts.length != 2) return 0;
    final bedMinutes = (int.tryParse(bedParts[0]) ?? 0) * 60 + (int.tryParse(bedParts[1]) ?? 0);
    final wakeMinutes = (int.tryParse(wakeParts[0]) ?? 0) * 60 + (int.tryParse(wakeParts[1]) ?? 0);
    double diff = (wakeMinutes - bedMinutes) / 60.0;
    if (diff < 0) diff += 24;
    return double.parse(diff.toStringAsFixed(1));
  }
}

/// A logged sleep entry (may contain multiple segments).
class SleepEntry {
  final DateTime date;
  final String bedTime; // First segment bed (backward compat)
  final String wakeTime; // Last segment wake (backward compat)
  final int quality; // 1-5 stars
  final double hoursSlept; // Total across all segments
  final List<SleepSegment>? segments;

  SleepEntry({
    required this.date,
    required this.bedTime,
    required this.wakeTime,
    required this.quality,
    required this.hoursSlept,
    this.segments,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String().split('T').first,
        'bedTime': bedTime,
        'wakeTime': wakeTime,
        'quality': quality,
        'hoursSlept': hoursSlept,
        if (segments != null)
          'segments': segments!.map((s) => s.toJson()).toList(),
      };

  factory SleepEntry.fromJson(Map<String, dynamic> json) {
    final segmentsRaw = json['segments'] as List<dynamic>?;
    final segments = segmentsRaw
        ?.map((s) => SleepSegment.fromJson(s as Map<String, dynamic>))
        .toList();
    return SleepEntry(
      date: DateTime.parse(json['date'] as String),
      bedTime: json['bedTime'] as String? ?? '22:00',
      wakeTime: json['wakeTime'] as String? ?? '06:00',
      quality: json['quality'] as int? ?? 3,
      hoursSlept: (json['hoursSlept'] as num?)?.toDouble() ?? 8,
      segments: segments,
    );
  }
}

/// Service for persisting and retrieving user data via SharedPreferences.
class UserDataService {
  static const _keyUserData = 'user_data';
  static const _keyHeightMeasurements = 'height_measurements';
  static const _keyLastMeasurementDate = 'last_measurement_date';
  static const _keyPlanStartDate = 'plan_start_date';
  static const _keyMealEntries = 'meal_entries';
  static const _keySleepEntries = 'sleep_entries';
  static const _keyStreakData = 'streak_data';
  static const _keyCompletedLevels = 'completed_levels';
  static const _keyHiveMigrated = 'hive_migrated_v2';

  // ── Legacy Migration ──

  /// One-time migration of legacy SharedPreferences lists into Hive.
  ///
  /// Must run at startup (after [HiveService.init]) BEFORE any reads or
  /// writes. Doing it lazily in the read path stranded legacy data whenever
  /// a write happened before the first read (the box was no longer empty, so
  /// the migration branch never fired).
  Future<void> migrateLegacyDataIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyHiveMigrated) == true) return;

    await _migrateList(prefs, _keyHeightMeasurements, HiveService.heightBox);
    await _migrateList(prefs, _keyMealEntries, HiveService.mealsBox);
    await _migrateList(prefs, _keySleepEntries, HiveService.sleepBox);

    await prefs.setBool(_keyHiveMigrated, true);
  }

  Future<void> _migrateList(SharedPreferences prefs, String key, Box box) async {
    final raw = prefs.getString(key);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final e in list) {
        await box.add(Map<String, dynamic>.from(e as Map));
      }
      await prefs.remove(key);
    } catch (_) {
      // Corrupt legacy blob — drop it so we don't retry forever.
      await prefs.remove(key);
    }
  }

  // ── Streak Tracking ──

  Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyStreakData);
    if (raw == null) return 0;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final streak = data['streak'] as int? ?? 0;
      final lastDateStr = data['lastDate'] as String?;
      if (lastDateStr == null) return 0;
      final lastDate = DateTime.tryParse(lastDateStr);
      if (lastDate == null) return 0;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final last = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final diff = today.difference(last).inDays;
      if (diff == 0) return streak; // already visited today
      if (diff == 1) return streak; // consecutive
      return 0; // gap -> streak broken
    } catch (_) {
      return 0;
    }
  }

  Future<void> markTodayVisited() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyStreakData);
    int streak = 1;
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final lastStreak = data['streak'] as int? ?? 0;
        final lastDateStr = data['lastDate'] as String?;
        if (lastDateStr != null) {
          final lastDate = DateTime.tryParse(lastDateStr);
          if (lastDate != null) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final last = DateTime(lastDate.year, lastDate.month, lastDate.day);
            final diff = today.difference(last).inDays;
            if (diff == 0) return; // already marked today
            if (diff == 1) streak = lastStreak + 1; // consecutive
            // else diff > 1 -> streak reset to 1
          }
        }
      } catch (_) {}
    }
    await prefs.setString(_keyStreakData, jsonEncode({
      'streak': streak,
      'lastDate': DateTime.now().toIso8601String().split('T').first,
    }));
  }

  // ── User Profile ──

  Future<void> saveUserData(PersistedUserData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserData, jsonEncode(data.toJson()));
  }

  Future<PersistedUserData?> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUserData);
    if (raw == null) return null;
    try {
      return PersistedUserData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── Height Measurements ──

  Future<void> addHeightMeasurement(double heightCm) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = HeightEntry(date: DateTime.now(), heightCm: heightCm);
    
    // Save to Hive
    await HiveService.heightBox.add(entry.toJson());
    
    await prefs.setString(
        _keyLastMeasurementDate, DateTime.now().toIso8601String().split('T').first);
  }

  Future<List<HeightEntry>> getHeightMeasurements() async {
    return HiveService.heightBox.values
        .map((e) => HeightEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<DateTime?> getLastMeasurementDate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyLastMeasurementDate);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<int> getDaysUntilNextMeasurement() async {
    final lastDate = await getLastMeasurementDate();
    if (lastDate == null) return 0;
    final nextDate = lastDate.add(const Duration(days: 30));
    final remaining = nextDate.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  Future<bool> canMeasureHeight() async {
    final days = await getDaysUntilNextMeasurement();
    return days <= 0;
  }

  Future<List<double>> getMeasurementHeights() async {
    final entries = await getHeightMeasurements();
    return entries.map((e) => e.heightCm).toList();
  }

  Future<void> updateCurrentHeight(double newHeightCm) async {
    final existing = await loadUserData();
    if (existing != null) {
      final updated = PersistedUserData(
        name: existing.name,
        gender: existing.gender,
        birthYear: existing.birthYear,
        currentHeightCm: newHeightCm,
        currentWeightKg: existing.currentWeightKg,
        fatherHeightCm: existing.fatherHeightCm,
        motherHeightCm: existing.motherHeightCm,
        activityLevel: existing.activityLevel,
        averageSleepHours: existing.averageSleepHours,
        analysisDepth: existing.analysisDepth,
        targetHeightCm: existing.targetHeightCm,
        activityDaysPerWeek: existing.activityDaysPerWeek,
      );
      await saveUserData(updated);
    }
  }

  // ── Plan Start Date ──

  Future<void> savePlanStartDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlanStartDate, date.toIso8601String().split('T').first);
  }

  Future<void> resetPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCompletedLevels, '[]');
    await savePlanStartDate(DateTime.now());
  }

  Future<DateTime?> getPlanStartDate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPlanStartDate);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<int> getCurrentDayNumber() async {
    final startDate = await getPlanStartDate();
    if (startDate == null) return 1;
    final diff = DateTime.now().difference(startDate).inDays;
    return (diff + 1).clamp(1, 90);
  }

  // ── Level Completion Tracking ──

  Future<void> markLevelCompleted(int levelNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyCompletedLevels);
    final completed = (raw != null)
        ? (jsonDecode(raw) as List<dynamic>).cast<int>()
        : <int>[];
    if (!completed.contains(levelNumber)) {
      completed.add(levelNumber);
      await prefs.setString(_keyCompletedLevels, jsonEncode(completed));
    }
  }

  Future<List<int>> getCompletedLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyCompletedLevels);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>).cast<int>();
    } catch (_) {
      return [];
    }
  }

  Future<bool> isLevelCompleted(int levelNumber) async {
    final completed = await getCompletedLevels();
    return completed.contains(levelNumber);
  }

  // ── Meal Entries ──

  Future<void> saveMealEntry(MealEntry entry) async {
    await HiveService.mealsBox.add(entry.toJson());
  }

  Future<List<MealEntry>> getMealEntries() async {
    return HiveService.mealsBox.values
        .map((e) => MealEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<MealEntry>> getTodayMealEntries() async {
    final all = await getMealEntries();
    final today = DateTime.now().toIso8601String().split('T').first;
    return all.where((e) => e.date.toIso8601String().split('T').first == today).toList();
  }

  Future<void> clearMealEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMealEntries);
  }

  // ── Sleep Entries ──

  Future<void> saveSleepEntry(SleepEntry entry) async {
    await HiveService.sleepBox.add(entry.toJson());
  }

  Future<List<SleepEntry>> getSleepEntries() async {
    return HiveService.sleepBox.values
        .map((e) => SleepEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<SleepEntry>> getThisWeekSleepEntries() async {
    final all = await getSleepEntries();
    final today = DateTime.now();
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    return all.where((e) => e.date.isAfter(sevenDaysAgo) && e.date.isBefore(today.add(const Duration(days: 1)))).toList();
  }

  Future<void> clearSleepEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySleepEntries);
  }
}

// ── Riverpod Providers ──

final userDataServiceProvider = Provider<UserDataService>((ref) {
  return UserDataService();
});

final persistedUserDataProvider = FutureProvider<PersistedUserData?>((ref) async {
  final service = ref.read(userDataServiceProvider);
  return service.loadUserData();
});

final heightMeasurementsProvider = FutureProvider<List<HeightEntry>>((ref) async {
  final service = ref.read(userDataServiceProvider);
  return service.getHeightMeasurements();
});

final planStartDateProvider = FutureProvider<DateTime?>((ref) async {
  final service = ref.read(userDataServiceProvider);
  return service.getPlanStartDate();
});

final daysUntilNextMeasurementProvider = FutureProvider<int>((ref) async {
  final service = ref.read(userDataServiceProvider);
  return service.getDaysUntilNextMeasurement();
});

final canMeasureHeightProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(userDataServiceProvider);
  return service.canMeasureHeight();
});

final currentDayNumberProvider = FutureProvider<int>((ref) async {
  final service = ref.read(userDataServiceProvider);
  return service.getCurrentDayNumber();
});

final completedLevelsProvider = FutureProvider<List<int>>((ref) async {
  final service = ref.read(userDataServiceProvider);
  return service.getCompletedLevels();
});

final todayMealEntriesProvider = FutureProvider<List<MealEntry>>((ref) async {
  final service = ref.read(userDataServiceProvider);
  return service.getTodayMealEntries();
});

final thisWeekSleepEntriesProvider = FutureProvider<List<SleepEntry>>((ref) async {
  final service = ref.read(userDataServiceProvider);
  return service.getThisWeekSleepEntries();
});

final streakProvider = FutureProvider<int>((ref) async {
  final service = ref.read(userDataServiceProvider);
  return service.getCurrentStreak();
});
