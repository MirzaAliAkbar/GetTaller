import 'package:flutter_test/flutter_test.dart';
import 'package:gettaller_app/core/utils/nutrition_goals.dart';

void main() {
  group('NutritionGoals', () {
    test('adolescents get the peak calcium target (1300mg)', () {
      final teen = NutritionGoals.forUser(
        ageYears: 15,
        isMale: true,
        weightKg: 60,
        activityDaysPerWeek: 3,
      );
      expect(teen.calcium, 1300);
      expect(teen.bandLabel, 'Peak Growth');
    });

    test('adults get the standard calcium target (1000mg)', () {
      final adult = NutritionGoals.forUser(
        ageYears: 30,
        isMale: true,
        weightKg: 80,
        activityDaysPerWeek: 3,
      );
      expect(adult.calcium, 1000);
      expect(adult.bandLabel, 'Maintenance');
    });

    test('goals differ across age groups (not one-size-fits-all)', () {
      final child = NutritionGoals.forUser(
          ageYears: 7, isMale: true, weightKg: 25, activityDaysPerWeek: 2);
      final teen = NutritionGoals.forUser(
          ageYears: 16, isMale: true, weightKg: 65, activityDaysPerWeek: 2);
      final adult = NutritionGoals.forUser(
          ageYears: 40, isMale: true, weightKg: 80, activityDaysPerWeek: 2);

      // Calorie targets should be distinct per band.
      expect({child.calories, teen.calories, adult.calories}.length, 3);
      // Protein scales with weight, so heavier users get more.
      expect(adult.protein, greaterThan(child.protein));
    });

    test('teen males target more calories than teen females', () {
      final male = NutritionGoals.forUser(
          ageYears: 16, isMale: true, weightKg: 65, activityDaysPerWeek: 3);
      final female = NutritionGoals.forUser(
          ageYears: 16, isMale: false, weightKg: 55, activityDaysPerWeek: 3);
      expect(male.calories, greaterThan(female.calories));
    });

    test('activity increases the calorie target', () {
      final sedentary = NutritionGoals.forUser(
          ageYears: 20, isMale: true, weightKg: 70, activityDaysPerWeek: 0);
      final active = NutritionGoals.forUser(
          ageYears: 20, isMale: true, weightKg: 70, activityDaysPerWeek: 7);
      expect(active.calories, greaterThan(sedentary.calories));
    });

    test('protein scales with body weight', () {
      final light = NutritionGoals.forUser(
          ageYears: 16, isMale: true, weightKg: 50, activityDaysPerWeek: 3);
      final heavy = NutritionGoals.forUser(
          ageYears: 16, isMale: true, weightKg: 80, activityDaysPerWeek: 3);
      expect(heavy.protein, greaterThan(light.protein));
    });
  });
}
