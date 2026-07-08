import 'package:flutter_test/flutter_test.dart';
import 'package:gettaller_app/core/utils/height_calculator.dart';

void main() {
  group('HeightCalculator Tests', () {
    test('calculatePotentialHeight returns correct Tanner mid-parental height', () {
      final maleHeight = HeightCalculator.calculatePotentialHeight(
        fatherHeightCm: 180,
        motherHeightCm: 160,
        isMale: true,
      );
      // (180 + 160 + 13) / 2 = 176.5
      expect(maleHeight, 176.5);

      final femaleHeight = HeightCalculator.calculatePotentialHeight(
        fatherHeightCm: 180,
        motherHeightCm: 160,
        isMale: false,
      );
      // (180 + 160 - 13) / 2 = 163.5
      expect(femaleHeight, 163.5);
    });

    test('getMode returns correct PredictionMode for ages', () {
      expect(HeightCalculator.getMode(10), PredictionMode.growthTracker);
      expect(HeightCalculator.getMode(17), PredictionMode.peakPotential);
      expect(HeightCalculator.getMode(22), PredictionMode.transitional);
      expect(HeightCalculator.getMode(30), PredictionMode.postureRestoration);
    });

    test('calculateAdjustedPrediction for Teen (Peak Potential)', () {
      final result = HeightCalculator.calculateAdjustedPrediction(
        fatherHeightCm: 173,
        motherHeightCm: 160,
        isMale: true,
        currentHeightCm: 174, // Already taller than dad
        ageYears: 17,
        weightKg: 65,
        averageSleepHours: 9, // Optimal sleep
        activityDaysPerWeek: 5,
      );

      expect(result.mode, PredictionMode.peakPotential);
      expect(result.peakHeight, greaterThan(174));
      expect(result.gaps['sleep'], 0.0); // Optimal sleep = 0 gap
    });

    test('calculateAdjustedPrediction for Adult (Posture Restoration)', () {
      final result = HeightCalculator.calculateAdjustedPrediction(
        fatherHeightCm: 180,
        motherHeightCm: 160,
        isMale: true,
        currentHeightCm: 180,
        ageYears: 30,
        weightKg: 80,
        averageSleepHours: 6,
        activityDaysPerWeek: 6,
      );

      expect(result.mode, PredictionMode.postureRestoration);
      // Base is current height (180), restoration adds ~2.5cm
      expect(result.peakHeight, closeTo(182.5, 0.1));
    });
  });
}
