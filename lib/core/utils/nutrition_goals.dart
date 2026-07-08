/// Age-, sex- and body-weight-aware daily nutrition goals.
///
/// Values are grounded in the U.S. Dietary Reference Intakes (DRI/RDA) with a
/// growth-app emphasis: calcium peaks during adolescence (peak bone-mineral
/// accrual), protein scales with body weight, and calories follow the
/// Estimated Energy Requirement bands adjusted for activity.
///
/// References (approximate, for a health/fitness context — not medical advice):
/// - Calcium RDA: 1,000 mg (4–8 & 19–50), 1,300 mg (9–18, peak bone growth),
///   1,200 mg (51+).
/// - Protein: ~1.4–1.5 g/kg during growth, ~1.2 g/kg for adults (above the bare
///   RDA of 0.85 g/kg, in line with active/growth needs).
/// - Calories: EER bands by age & sex, plus a modest activity bump.
class NutritionGoals {
  final int calories; // kcal/day
  final int protein; // g/day
  final int calcium; // mg/day

  /// Short human label for the life-stage band, e.g. "Peak Growth".
  final String bandLabel;

  const NutritionGoals({
    required this.calories,
    required this.protein,
    required this.calcium,
    required this.bandLabel,
  });

  /// Sensible fallback used before the user's profile has loaded.
  static const NutritionGoals fallback = NutritionGoals(
    calories: 2200,
    protein: 90,
    calcium: 1300,
    bandLabel: '',
  );

  static NutritionGoals forUser({
    required int ageYears,
    required bool isMale,
    required double weightKg,
    required int activityDaysPerWeek,
  }) {
    // ── Calcium (bone-growth critical) ──
    final int calcium;
    if (ageYears <= 8) {
      calcium = 1000;
    } else if (ageYears <= 18) {
      calcium = 1300; // adolescence — peak bone-mineral accrual
    } else if (ageYears <= 50) {
      calcium = 1000;
    } else {
      calcium = 1200;
    }

    // ── Protein (body-weight based, higher during growth) ──
    final double gramsPerKg;
    if (ageYears <= 13) {
      gramsPerKg = 1.4;
    } else if (ageYears <= 18) {
      gramsPerKg = 1.5; // adolescent growth spurt
    } else {
      gramsPerKg = 1.2;
    }
    // Guard against unrealistic weights, then round to the nearest 5 g.
    final safeWeight = weightKg.clamp(20.0, 200.0);
    final protein = ((safeWeight * gramsPerKg) / 5).round() * 5;

    // ── Calories (EER band + activity bump) ──
    int baseCalories;
    if (ageYears <= 8) {
      baseCalories = 1600;
    } else if (ageYears <= 13) {
      baseCalories = isMale ? 2200 : 2000;
    } else if (ageYears <= 18) {
      baseCalories = isMale ? 2800 : 2100; // teen growth spurt, males highest
    } else if (ageYears <= 30) {
      baseCalories = isMale ? 2600 : 2000;
    } else if (ageYears <= 50) {
      baseCalories = isMale ? 2400 : 1900;
    } else {
      baseCalories = isMale ? 2200 : 1800;
    }
    // Activity: up to ~+400 kcal for a fully active week.
    final activityBump = activityDaysPerWeek.clamp(0, 7) * 60;
    // Round total to the nearest 50 kcal for a clean target.
    final calories = ((baseCalories + activityBump) / 50).round() * 50;

    // ── Life-stage band label ──
    final String bandLabel;
    if (ageYears <= 8) {
      bandLabel = 'Childhood';
    } else if (ageYears <= 18) {
      bandLabel = 'Peak Growth';
    } else if (ageYears <= 24) {
      bandLabel = 'Late Growth';
    } else {
      bandLabel = 'Maintenance';
    }

    return NutritionGoals(
      calories: calories,
      protein: protein,
      calcium: calcium,
      bandLabel: bandLabel,
    );
  }

  /// Formats an integer with thousands separators, e.g. 2200 -> "2,200".
  static String withThousands(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
