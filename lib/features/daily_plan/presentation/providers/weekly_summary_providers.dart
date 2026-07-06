import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/user_data_service.dart';

/// Weekly sleep summary — averages from logged days only (skips missing days).
final weeklySleepSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(userDataServiceProvider);
  final entries = await service.getThisWeekSleepEntries();

  if (entries.isEmpty) {
    return {
      'avgHours': 0.0,
      'avgQuality': 0,
      'daysLogged': 0,
      'totalDays': 7,
      'missedDays': _getMissedDayNames(0),
      'hasData': false,
    };
  }

  final avgHours = entries.fold<double>(0, (s, e) => s + e.hoursSlept) / entries.length;
  final avgQuality = entries.fold<double>(0, (s, e) => s + e.quality) / entries.length;

  // Find which days were logged
  final loggedWeekdays = entries.map((e) => e.date.weekday).toSet();
  final missedDays = List.generate(7, (i) => i + 1)
      .where((wd) => !loggedWeekdays.contains(wd))
      .map(_weekdayToName)
      .toList();

  return {
    'avgHours': double.parse(avgHours.toStringAsFixed(1)),
    'avgQuality': double.parse(avgQuality.toStringAsFixed(1)),
    'daysLogged': entries.length,
    'totalDays': 7,
    'missedDays': missedDays,
    'hasData': true,
  };
});

/// Weekly meal summary — averages from logged days only (skips missing days).
final weeklyMealSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(userDataServiceProvider);
  final entries = await service.getMealEntries();

  // Filter to this week only
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);

  final thisWeek = entries.where((e) {
    return !e.date.isBefore(weekStartDay);
  }).toList();

  if (thisWeek.isEmpty) {
    return {
      'avgCalories': 0,
      'avgProtein': 0.0,
      'avgCalcium': 0.0,
      'daysLogged': 0,
      'totalDays': 7,
      'missedDays': _getMissedDayNames(0),
      'hasData': false,
    };
  }

  // Group by day and calculate daily totals
  final dailyTotals = <String, Map<String, double>>{};
  for (final entry in thisWeek) {
    final dayKey = entry.date.toIso8601String().split('T').first;
    dailyTotals.putIfAbsent(dayKey, () => {'calories': 0, 'protein': 0, 'calcium': 0});
    dailyTotals[dayKey]!['calories'] = dailyTotals[dayKey]!['calories']! + entry.calories;
    dailyTotals[dayKey]!['protein'] = dailyTotals[dayKey]!['protein']! + entry.protein;
    dailyTotals[dayKey]!['calcium'] = dailyTotals[dayKey]!['calcium']! + entry.calcium;
  }

  final daysLogged = dailyTotals.length;
  final totalCal = dailyTotals.values.fold<double>(0, (s, d) => s + d['calories']!);
  final totalProtein = dailyTotals.values.fold<double>(0, (s, d) => s + d['protein']!);
  final totalCalcium = dailyTotals.values.fold<double>(0, (s, d) => s + d['calcium']!);

  final loggedWeekdays = dailyTotals.keys.map((dk) {
    return DateTime.parse(dk).weekday;
  }).toSet();

  final missedDays = List.generate(7, (i) => i + 1)
      .where((wd) => !loggedWeekdays.contains(wd))
      .map(_weekdayToName)
      .toList();

  return {
    'avgCalories': (totalCal / daysLogged).round(),
    'avgProtein': double.parse((totalProtein / daysLogged).toStringAsFixed(1)),
    'avgCalcium': (totalCalcium / daysLogged).round(),
    'daysLogged': daysLogged,
    'totalDays': 7,
    'missedDays': missedDays,
    'hasData': true,
  };
});

/// Check if weekly recap should be shown.
final shouldShowRecapProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final lastRecap = prefs.getString('last_recap_shown_date');
  final now = DateTime.now();

  // Show on Monday (start of week) or if never shown
  if (lastRecap == null) return true;

  final lastDate = DateTime.tryParse(lastRecap);
  if (lastDate == null) return true;

  // Show if it's a new week (Monday) and recap hasn't been shown this week
  final lastWeekStart = lastDate.subtract(Duration(days: lastDate.weekday - 1));
  final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));

  return currentWeekStart.isAfter(lastWeekStart);
});

String _weekdayToName(int weekday) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return names[weekday - 1];
}

List<String> _getMissedDayNames(int daysLogged) {
  // Return all 7 days as missed if none logged
  if (daysLogged == 0) {
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  }
  return [];
}
