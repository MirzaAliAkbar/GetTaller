/// Complete onboarding data model — collected across the onboarding steps.
class OnboardingData {
  final String? name;
  final String gender; // 'male' | 'female'
  final DateTime birthDate;
  final double currentHeightCm;
  final double currentWeightKg;
  final double fatherHeightCm;
  final double motherHeightCm;
  final String activityLevel; // 'sedentary' | 'moderate' | 'active'
  final double averageSleepHours;
  final String analysisDepth; // 'fast' | 'accurate'
  final double? targetHeightCm;
  final int activityDaysPerWeek;
  final String? referralCode;

  const OnboardingData({
    this.name,
    required this.gender,
    required this.birthDate,
    required this.currentHeightCm,
    required this.currentWeightKg,
    required this.fatherHeightCm,
    required this.motherHeightCm,
    this.activityLevel = 'moderate',
    required this.averageSleepHours,
    required this.analysisDepth,
    this.targetHeightCm,
    required this.activityDaysPerWeek,
    this.referralCode,
  });

  int get ageYears {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  bool get isMale => gender == 'male';

  OnboardingData copyWith({
    String? name,
    String? gender,
    DateTime? birthDate,
    double? currentHeightCm,
    double? currentWeightKg,
    double? fatherHeightCm,
    double? motherHeightCm,
    String? activityLevel,
    double? averageSleepHours,
    String? analysisDepth,
    double? targetHeightCm,
    int? activityDaysPerWeek,
    String? referralCode,
  }) {
    return OnboardingData(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      currentHeightCm: currentHeightCm ?? this.currentHeightCm,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      fatherHeightCm: fatherHeightCm ?? this.fatherHeightCm,
      motherHeightCm: motherHeightCm ?? this.motherHeightCm,
      activityLevel: activityLevel ?? this.activityLevel,
      averageSleepHours: averageSleepHours ?? this.averageSleepHours,
      analysisDepth: analysisDepth ?? this.analysisDepth,
      targetHeightCm: targetHeightCm ?? this.targetHeightCm,
      activityDaysPerWeek: activityDaysPerWeek ?? this.activityDaysPerWeek,
      referralCode: referralCode ?? this.referralCode,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'gender': gender,
    'birthDate': birthDate.toIso8601String(),
    'currentHeightCm': currentHeightCm,
    'currentWeightKg': currentWeightKg,
    'fatherHeightCm': fatherHeightCm,
    'motherHeightCm': motherHeightCm,
    'activityLevel': activityLevel,
    'averageSleepHours': averageSleepHours,
    'analysisDepth': analysisDepth,
    'targetHeightCm': targetHeightCm,
    'activityDaysPerWeek': activityDaysPerWeek,
    'ageYears': ageYears,
    if (referralCode != null) 'referralCode': referralCode,
  };

  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    return OnboardingData(
      name: json['name'] as String?,
      gender: json['gender'] as String,
      birthDate: DateTime.parse(json['birthDate'] as String),
      currentHeightCm: (json['currentHeightCm'] as num).toDouble(),
      currentWeightKg: (json['currentWeightKg'] as num).toDouble(),
      fatherHeightCm: (json['fatherHeightCm'] as num).toDouble(),
      motherHeightCm: (json['motherHeightCm'] as num).toDouble(),
      activityLevel: json['activityLevel'] as String? ?? 'moderate',
      averageSleepHours: (json['averageSleepHours'] as num).toDouble(),
      analysisDepth: json['analysisDepth'] as String,
      targetHeightCm: (json['targetHeightCm'] as num?)?.toDouble(),
      activityDaysPerWeek: (json['activityDaysPerWeek'] as num).toInt(),
      referralCode: json['referralCode'] as String?,
    );
  }
}
