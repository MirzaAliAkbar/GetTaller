import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/onboarding_data.dart';

/// Manages the onboarding flow state.
class OnboardingNotifier extends StateNotifier<OnboardingData?> {
  OnboardingNotifier() : super(null);

  bool get isComplete => state != null;

  void setName(String name) {
    state = (state ?? _emptyData).copyWith(name: name);
  }

  void setGender(String gender) {
    state = (state ?? _emptyData).copyWith(gender: gender);
  }

  void setBirthDate(DateTime date) {
    state = (state ?? _emptyData).copyWith(birthDate: date);
  }

  void setMeasurements({
    required double heightCm,
    required double weightKg,
  }) {
    state = (state ?? _emptyData).copyWith(
      currentHeightCm: heightCm,
      currentWeightKg: weightKg,
    );
  }

  void setParentHeights({
    required double fatherHeightCm,
    required double motherHeightCm,
  }) {
    state = (state ?? _emptyData).copyWith(
      fatherHeightCm: fatherHeightCm,
      motherHeightCm: motherHeightCm,
    );
  }

  void setActivityLevel(String level) {
    state = (state ?? _emptyData).copyWith(activityLevel: level);
    // Also set activity days based on level
    int days;
    switch (level) {
      case 'sedentary':
        days = 0;
        break;
      case 'moderate':
        days = 4;
        break;
      case 'active':
        days = 6;
        break;
      default:
        days = 3;
    }
    state = state!.copyWith(activityDaysPerWeek: days);
  }

  void setSleepHours(double hours) {
    state = (state ?? _emptyData).copyWith(averageSleepHours: hours);
  }

  void setAnalysisDepth(String depth) {
    state = (state ?? _emptyData).copyWith(analysisDepth: depth);
  }

  void setTargetHeight(double height) {
    state = (state ?? _emptyData).copyWith(targetHeightCm: height);
  }

  void setActivityDays(int days) {
    state = (state ?? _emptyData).copyWith(activityDaysPerWeek: days);
  }

  void setReferralCode(String? code) {
    state = (state ?? _emptyData).copyWith(referralCode: code);
  }

  void reset() => state = null;

  OnboardingData get _emptyData => OnboardingData(
    gender: '',
    birthDate: DateTime(2000, 1, 1),
    currentHeightCm: 160,
    currentWeightKg: 55,
    fatherHeightCm: 175,
    motherHeightCm: 162,
    activityLevel: 'moderate',
    averageSleepHours: 7,
    analysisDepth: 'accurate',
    activityDaysPerWeek: 3,
  );
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingData?>(
  (ref) => OnboardingNotifier(),
);
