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

  final avgHours = entries.fold<double>(0.0, (s, e) => s + e.hoursSlept) / entries.length;
  final avgQuality = entries.fold<double>(0.0, (s, e) => s + e.quality.toDouble()) / entries.length;

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
    dailyTotals.putIfAbsent(dayKey, () => {'calories': 0.0, 'protein': 0.0, 'calcium': 0.0});
    dailyTotals[dayKey]!['calories'] = dailyTotals[dayKey]!['calories']! + entry.calories.toDouble();
    dailyTotals[dayKey]!['protein'] = dailyTotals[dayKey]!['protein']! + entry.protein.toDouble();
    dailyTotals[dayKey]!['calcium'] = dailyTotals[dayKey]!['calcium']! + entry.calcium.toDouble();
  }

  final daysLogged = dailyTotals.length;
  final totalCal = dailyTotals.values.fold<double>(0.0, (s, d) => s + d['calories']!);
  final totalProtein = dailyTotals.values.fold<double>(0.0, (s, d) => s + d['protein']!);
  final totalCalcium = dailyTotals.values.fold<double>(0.0, (s, d) => s + d['calcium']!);

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

/// Whether to show the weekly-recap badge on the dashboard.
///
/// The badge appears at the start of each week (Monday) and lingers all week
/// until the user opens that week's recap — at which point it hides until the
/// next week begins. Because weeks start on Monday, "not viewed this week" is
/// exactly the desired behaviour; no separate weekday gate is needed.
final weeklyRecapBadgeProvider = FutureProvider<bool>((ref) async {
  final now = DateTime.now();

  final prefs = await SharedPreferences.getInstance();
  final lastRecap = prefs.getString('last_recap_shown_date');
  if (lastRecap == null) return true;

  final lastDate = DateTime.tryParse(lastRecap);
  if (lastDate == null) return true;

  // Show only if this week's recap hasn't been viewed yet. Compare week starts
  // normalized to date-only so a same-day time-of-day difference can't leak
  // through and re-show the badge after it's already been opened today.
  return _weekStart(now).isAfter(_weekStart(lastDate));
});

/// Records that this week's recap has been viewed, so the badge hides.
Future<void> markWeeklyRecapViewed() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
      'last_recap_shown_date', DateTime.now().toIso8601String().split('T').first);
}

DateTime _weekStart(DateTime d) {
  final ws = d.subtract(Duration(days: d.weekday - 1));
  return DateTime(ws.year, ws.month, ws.day);
}

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
