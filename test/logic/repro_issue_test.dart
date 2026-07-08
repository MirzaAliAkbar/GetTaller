import 'package:flutter_test/flutter_test.dart';
import 'package:gettaller_app/core/utils/height_calculator.dart';

void main() {
  test('Reproduction: 11yo Boy 140cm Prediction', () {
    final result = HeightCalculator.calculateAdjustedPrediction(
      fatherHeightCm: 173,
      motherHeightCm: 165,
      isMale: true,
      currentHeightCm: 140,
      ageYears: 11,
      weightKg: 40,
      averageSleepHours: 9,
      activityDaysPerWeek: 5,
    );

    print('11yo Boy (140cm) Predicted Peak: ${result.peakHeight}');
    expect(result.peakHeight, greaterThan(180));
  });
}
