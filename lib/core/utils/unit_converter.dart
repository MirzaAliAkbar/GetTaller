import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class UnitConverter {
  static bool _isMetric = true;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isMetric = prefs.getBool(AppConstants.prefUnitSystem) ?? true;
  }

  static bool get isMetric => _isMetric;

  static Future<void> setMetric(bool metric) async {
    _isMetric = metric;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefUnitSystem, metric);
  }

  static String formatHeight(double cm) {
    if (_isMetric) return '${cm.toStringAsFixed(1)} cm';
    final totalInches = cm / 2.54;
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return "$feet'${inches.toStringAsFixed(0)}\"";
  }

  static String formatWeight(double kg) {
    if (_isMetric) return '${kg.toStringAsFixed(1)} kg';
    return '${(kg * 2.20462).toStringAsFixed(1)} lbs';
  }

  static String heightUnit() => _isMetric ? 'cm' : 'inches';
  static String weightUnit() => _isMetric ? 'kg' : 'lbs';

  static double inputToCm(double value) => _isMetric ? value : value * 2.54;
  static double inputToKg(double value) => _isMetric ? value : value * 0.453592;
}
