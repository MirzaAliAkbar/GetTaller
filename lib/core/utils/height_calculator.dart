import 'dart:math';
import 'constants.dart';

/// Height prediction calculator — implements the Tanner mid-parental method
/// with BMI, sleep, and activity adjustments (Blueprint §6).
class HeightCalculator {
  /// Mid-Parental Height (Tanner Method) — Blueprint §6.1
  static double calculatePotentialHeight({
    required double fatherHeightCm,
    required double motherHeightCm,
    required bool isMale,
  }) {
    if (isMale) {
      return (fatherHeightCm + motherHeightCm + AppConstants.tannerConstant) / 2;
    } else {
      return (fatherHeightCm + motherHeightCm - AppConstants.tannerConstant) / 2;
    }
  }

  /// BMI adjustment factor (Blueprint §6.2.3)
  static double calculateBmiAdjustment(double bmi) {
    if (bmi < AppConstants.bmiOptimalMin) {
      // Low BMI penalty: linearly scale from 0 to -1.5
      return max(-1.5, (bmi - AppConstants.bmiOptimalMin) / 2);
    } else if (bmi > AppConstants.bmiOptimalMax) {
      // High BMI compression penalty: linearly scale from 0 to -1.5
      return max(-1.5, (AppConstants.bmiOptimalMax - bmi) / 3);
    }
    return 0.0;
  }

  /// Sleep quality adjustment (Blueprint §6.2.4)
  static double calculateSleepAdjustment(double averageSleepHours) {
    if (averageSleepHours < AppConstants.minSleepHours) {
      return -1.0; // HGH deficiency
    } else if (averageSleepHours >= 8 && averageSleepHours <= 10) {
      return 0.5; // Optimal HGH release
    } else if (averageSleepHours > 10) {
      return 0.0; // Too much sleep — neutral
    }
    return 0.0; // Adequate but not optimal = neutral
  }

  /// Activity level adjustment (Blueprint §6.2.5)
  static double calculateActivityAdjustment(int daysPerWeek) {
    if (daysPerWeek <= 1) return 0.0;
    if (daysPerWeek <= 4) return 0.5;
    return 1.0; // 5+ days — maximum benefit
  }

  /// Growth completion percentage (Blueprint §6.3)
  static double calculateGrowthCompletion({
    required int ageYears,
    required bool isMale,
    required double currentHeightCm,
    required double predictedHeightCm,
  }) {
    final closureAge = isMale
        ? AppConstants.maleGrowthClosureAge
        : AppConstants.femaleGrowthClosureAge;

    if (ageYears >= closureAge) return 1.0;

    // Age-based completion
    final ageCompletion = ageYears / closureAge;

    // Height-based completion (how close they already are to predicted)
    final heightRatio = currentHeightCm / predictedHeightCm;
    final heightCompletion = heightRatio.clamp(0.6, 1.0);

    // Blended: 60% age-based, 40% height-based
    return (ageCompletion * 0.6 + heightCompletion * 0.4).clamp(0.0, 1.0);
  }

  /// Calculate global percentile (Blueprint §6.4)
  static double calculatePercentile({
    required double heightCm,
    required bool isMale,
    required int ageYears,
  }) {
    final avg = isMale ? AppConstants.avgMaleHeightCm : AppConstants.avgFemaleHeightCm;
    final stdDev = isMale ? 7.0 : 6.0; // Approximate standard deviation

    // Z-score
    final z = (heightCm - avg) / stdDev;

    // Convert Z-score to percentile using normal CDF approximation
    return _normalCdf(z);
  }

  /// Adjusted predicted height with all factors (Blueprint §6.2)
  static double calculateAdjustedPrediction({
    required double fatherHeightCm,
    required double motherHeightCm,
    required bool isMale,
    required double currentHeightCm,
    required int ageYears,
    required double weightKg,
    required double averageSleepHours,
    required int activityDaysPerWeek,
  }) {
    final basePrediction = calculatePotentialHeight(
      fatherHeightCm: fatherHeightCm,
      motherHeightCm: motherHeightCm,
      isMale: isMale,
    );

    final heightM = currentHeightCm / 100;
    final bmi = weightKg / (heightM * heightM);

    final bmiAdj = calculateBmiAdjustment(bmi);
    final sleepAdj = calculateSleepAdjustment(averageSleepHours);
    final activityAdj = calculateActivityAdjustment(activityDaysPerWeek);

    // Total adjustment
    double totalAdjustment = bmiAdj + sleepAdj + activityAdj;

    // Clamp adjustment to realistic range
    totalAdjustment = totalAdjustment.clamp(-3.0, 3.0);

    final closureAge = isMale
        ? AppConstants.maleGrowthClosureAge
        : AppConstants.femaleGrowthClosureAge;

    // Blend with current height only near growth closure — children are still growing
    final diff = (basePrediction - currentHeightCm).abs();
    final yearsLeftForBlend = (closureAge - ageYears).clamp(0, closureAge);
    double adjustedPrediction;

    if (yearsLeftForBlend <= 3) {
      // Near closure: weight toward current height (realistic cap)
      if (diff > 20) {
        adjustedPrediction = (basePrediction * 0.4 + currentHeightCm * 0.6) + totalAdjustment;
      } else if (diff > 10) {
        adjustedPrediction = (basePrediction * 0.6 + currentHeightCm * 0.4) + totalAdjustment;
      } else {
        adjustedPrediction = basePrediction + totalAdjustment;
      }
    } else {
      // Far from closure: child is still growing, use Tanner base prediction
      adjustedPrediction = basePrediction + totalAdjustment;
    }

    // Apply age clamp — near closure age, clamp towards current height
    final yearsLeft = (closureAge - ageYears).clamp(0, closureAge);
    final ageClampFactor = 1.0 - (yearsLeft / closureAge);

    if (ageClampFactor > 0.7) {
      // Significantly clamped: heavily weight current height
      adjustedPrediction = currentHeightCm + (adjustedPrediction - currentHeightCm) * (1 - ageClampFactor);
    }

    // ── Placebo & Posture Boost ──
    // Minimum +1cm for every user: exercises improve posture (which adds height)
    // and the belief/placebo effect drives adherence for better results.
    // +1-3cm additional for users with growth years left.
    // Disclosed in the app's About & Privacy section.
    adjustedPrediction += 1.0; // Base: posture + belief for all users
    if (yearsLeft >= 5) {
      adjustedPrediction += 2.0; // +3 total
    } else if (yearsLeft >= 3) {
      adjustedPrediction += 1.0; // +2 total
    } else if (yearsLeft >= 1) {
      adjustedPrediction += 0.0; // +1 total (base only)
    }
    // yearsLeft < 1: just the +1cm base

    return adjustedPrediction.clamp(currentHeightCm - 5, basePrediction + 10);
  }

  /// Standard normal CDF (Abramowitz and Stegun approximation)
  static double _normalCdf(double z) {
    if (z < -6) return 0.0;
    if (z > 6) return 1.0;

    const double b1 = 0.31938153;
    const double b2 = -0.356563782;
    const double b3 = 1.781477937;
    const double b4 = -1.821255978;
    const double b5 = 1.330274429;
    const double p = 0.2316419;
    const double c = 0.39894228;

    final double x = z.abs();
    final double t = 1.0 / (1.0 + p * x);
    final double poly = c * exp(-z * z / 2) *
        (t * (b1 + t * (b2 + t * (b3 + t * (b4 + t * b5)))));

    return z >= 0 ? 1.0 - poly : poly;
  }

  /// Potential gain from current height to adjusted prediction
  static double calculateHeightGain({
    required double currentHeightCm,
    required double predictedHeightCm,
  }) {
    return max(0, predictedHeightCm - currentHeightCm);
  }

  /// Weekly projected height increments over 90-day plan
  static List<double> projectGrowthCurve({
    required double currentHeightCm,
    required double predictedHeightCm,
    required int ageYears,
    required bool isMale,
  }) {
    final totalGain = calculateHeightGain(
      currentHeightCm: currentHeightCm,
      predictedHeightCm: predictedHeightCm,
    );

    const weeks = 12; // 90-day plan ≈ 12 weeks
    List<double> curve = [];

    for (int w = 0; w <= weeks; w++) {
      final progress = w / weeks;
      final projected = currentHeightCm + totalGain * progress;
      curve.add(projected);
    }

    return curve;
  }
}
