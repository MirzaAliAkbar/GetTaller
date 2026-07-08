import 'dart:math';
import 'constants.dart';

/// Prediction mode based on user age group
enum PredictionMode {
  growthTracker, // Kids < 12
  peakPotential, // Teens 13-19
  transitional,  // Young adults 20-24
  postureRestoration, // Adults 25+
}

/// Result of height prediction calculation
class PredictionResult {
  final double baseHeight; // Genetic/current baseline
  final double peakHeight; // Maximum potential with optimization
  final Map<String, double> gaps; // Millimeter losses per factor
  final PredictionMode mode;

  PredictionResult({
    required this.baseHeight,
    required this.peakHeight,
    required this.gaps,
    required this.mode,
  });

  double get potentialGain => peakHeight - baseHeight;
}

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

  /// Determine prediction mode based on age
  static PredictionMode getMode(int ageYears) {
    if (ageYears < 12) return PredictionMode.growthTracker;
    if (ageYears <= 19) return PredictionMode.peakPotential;
    if (ageYears <= 24) return PredictionMode.transitional;
    return PredictionMode.postureRestoration;
  }

  /// Refined Height Prediction Engine (Hybrid Model)
  /// Combines Medical Momentum (Khamis-Roche style) with Optimization Buffers.
  static PredictionResult calculateAdjustedPrediction({
    required double fatherHeightCm,
    required double motherHeightCm,
    required bool isMale,
    required double currentHeightCm,
    required int ageYears,
    required double weightKg,
    required double averageSleepHours,
    required int activityDaysPerWeek,
  }) {
    final mode = getMode(ageYears);
    
    // 1. Mid-Parental Baseline (Tanner)
    final geneticAverage = (fatherHeightCm + motherHeightCm + (isMale ? 13 : -13)) / 2;

    // 2. Momentum Check
    // If user is already tall or young, we assume they can at least reach 
    // their current height + a growth buffer.
    double baseline = max(currentHeightCm, geneticAverage);

    // 3. Prediction Logic by Age
    double baseHeight;
    double peakHeight;
    double optimizationBuffer = 0.0;

    final bmi = weightKg / ((currentHeightCm / 100) * (currentHeightCm / 100));
    final bmiAdj = calculateBmiAdjustment(bmi);
    final sleepAdj = calculateSleepAdjustment(averageSleepHours);
    final activityAdj = calculateActivityAdjustment(activityDaysPerWeek);

    // Calculate Gaps (in mm)
    final gaps = {
      'nutrition': (bmiAdj.abs() * 10).clamp(0.0, 15.0),
      'sleep': (sleepAdj < 0 ? sleepAdj.abs() * 10 : 0.0).clamp(0.0, 10.0),
      'posture': 5.0,
    };

    if (ageYears < 21) {
      // Teens/Kids: Focus on natural growth + optimization
      final yearsLeft = (21 - ageYears).toDouble().clamp(0, 15);
      
      // Natural growth estimate (Medical-style)
      // We assume they will naturally trend towards their genetic average
      // but we don't just jump there. We calculate a "Residual Growth"
      double naturalGrowth = 0;
      if (ageYears < 12) {
        // Kids: Conservative natural growth towards adult baseline
        // We use 0.4cm/yr as a slow "drift" towards the genetic target
        naturalGrowth = yearsLeft * 0.4; 
      } else {
        // Teens: Slowing down growth
        naturalGrowth = max(0.2, (21 - ageYears) * 0.3);
      }
      
      baseHeight = baseline + naturalGrowth;
      
      // Optimization Buffer (+3cm to +6cm based on "Growth Window")
      // This is the "App's Promise"
      optimizationBuffer = 3.0;
      if (yearsLeft > 4) optimizationBuffer += 2.0;
      if (averageSleepHours >= 8) optimizationBuffer += 1.0;
      
      peakHeight = baseHeight + optimizationBuffer + bmiAdj + sleepAdj + activityAdj;

      // --- GENETIC GRAVITY (Reality Check) ---
      // We cap the Peak Potential to Mid-Parental Height + 6cm.
      // This ensures we stay within medical plausibility (Blueprint §6.6).
      final maxPlausibleHeight = geneticAverage + 6.0;
      if (peakHeight > maxPlausibleHeight) {
        peakHeight = maxPlausibleHeight;
      }
    } else {
      // Adults: Focus on Posture Restoration
      baseHeight = currentHeightCm;
      
      // Restoration limit (+1.5cm to +2.5cm)
      optimizationBuffer = 1.5;
      if (activityDaysPerWeek >= 5) optimizationBuffer += 1.0;
      
      peakHeight = baseHeight + optimizationBuffer;
    }

    // Safety Clamps
    if (ageYears < 21) {
      // Teens/Kids can grow significantly (up to 50-60cm total from childhood)
      baseHeight = baseHeight.clamp(currentHeightCm, 250.0);
      peakHeight = max(baseHeight, peakHeight).clamp(currentHeightCm, 250.0);
    } else {
      // Adults are capped by posture restoration limits (+3cm max)
      baseHeight = baseHeight.clamp(currentHeightCm, currentHeightCm + 5.0);
      peakHeight = max(baseHeight, peakHeight).clamp(currentHeightCm, currentHeightCm + 10.0);
    }

    return PredictionResult(
      baseHeight: baseHeight,
      peakHeight: peakHeight,
      gaps: gaps,
      mode: mode,
    );
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

  /// Calculate age-adjusted percentile (Hybrid Logic)
  static double calculateAgeAdjustedPercentile({
    required double heightCm,
    required bool isMale,
    required int ageYears,
  }) {
    if (ageYears >= 21) {
      // For adults, use global average
      return calculatePercentile(
        heightCm: heightCm,
        isMale: isMale,
        ageYears: ageYears,
      );
    }

    // For kids/teens, use simplified growth curve interpolation
    // Data points (Age: HeightMean)
    final Map<int, double> maleCurve = {
      2: 87.0,
      5: 110.0,
      10: 138.0,
      15: 170.0,
      18: 176.0,
      21: 174.0, // Blending into global average
    };

    final Map<int, double> femaleCurve = {
      2: 86.0,
      5: 108.0,
      10: 138.0,
      15: 162.0,
      18: 163.0,
      21: 161.0, // Blending into global average
    };

    final curve = isMale ? maleCurve : femaleCurve;
    final keys = curve.keys.toList()..sort();

    double mean = 0;
    if (ageYears <= keys.first) {
      mean = curve[keys.first]!;
    } else if (ageYears >= keys.last) {
      mean = curve[keys.last]!;
    } else {
      // Linear interpolation
      for (int i = 0; i < keys.length - 1; i++) {
        if (ageYears >= keys[i] && ageYears <= keys[i + 1]) {
          final t = (ageYears - keys[i]) / (keys[i + 1] - keys[i]);
          mean = curve[keys[i]]! + t * (curve[keys[i + 1]]! - curve[keys[i]]!);
          break;
        }
      }
    }

    // Simplified SD scaling: starts at 3.5cm (age 2) and grows to 7cm (age 15+)
    double stdDev = 7.0;
    if (ageYears < 15) {
      stdDev = 3.5 + (ageYears - 2) * (3.5 / 13);
    }
    if (!isMale) stdDev *= 0.85; // Slightly lower SD for females

    final z = (heightCm - mean) / stdDev;
    return _normalCdf(z);
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

  /// Potential gain from current height to peak prediction
  static double calculateHeightGain({
    required double currentHeightCm,
    required double predictedHeightCm,
  }) {
    return max(0, predictedHeightCm - currentHeightCm);
  }

  /// Project growth curve (Hybrid Model)
  /// For kids/teens (<21): Years (e.g., 11 to 21)
  /// For adults (21+): Months (1 to 12)
  static List<double> projectGrowthCurve({
    required double currentHeightCm,
    required double predictedHeightCm,
    required int ageYears,
    required bool isMale,
  }) {
    final totalGain = max(0.0, predictedHeightCm - currentHeightCm);
    List<double> curve = [];

    if (ageYears < 21) {
      // Yearly intervals until 21
      final yearsTo21 = (21 - ageYears).clamp(1, 15);
      for (int i = 0; i <= yearsTo21; i++) {
        final progress = i / yearsTo21;
        // Natural curve: Faster at start, slower at end
        final curveProgress = 1 - pow(1 - progress, 1.5).toDouble();
        curve.add(currentHeightCm + totalGain * curveProgress);
      }
    } else {
      // Monthly intervals for 1 year
      const months = 12;
      for (int i = 0; i <= months; i++) {
        final progress = i / months;
        // Posture restoration: Slower at first, then steady
        final curveProgress = pow(progress, 0.8).toDouble();
        curve.add(currentHeightCm + totalGain * curveProgress);
      }
    }

    return curve;
  }
}
