import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// Exercise model — Blueprint §7.4
class ExerciseModel extends Equatable {
  final String id;
  final String category;
  final int durationSeconds;
  final int setsCount;
  final int restSeconds;
  final String? videoUrl;
  final int difficultyLevel; // 1-3
  final Map<String, String> names;
  final Map<String, String> descriptions;
  final Map<String, List<String>> steps;
  final Map<String, String> breathingPattern;

  const ExerciseModel({
    required this.id,
    required this.category,
    required this.durationSeconds,
    required this.setsCount,
    required this.restSeconds,
    this.videoUrl,
    required this.difficultyLevel,
    this.names = const {},
    this.descriptions = const {},
    this.steps = const {},
    this.breathingPattern = const {},
  });

  String localizedName(String locale) => names[locale] ?? names['en'] ?? id;
  String localizedDescription(String locale) => descriptions[locale] ?? descriptions['en'] ?? '';

  String get categoryIcon {
    switch (category) {
      case 'spine': return '🦴';
      case 'hanging': return '🤸';
      case 'hip': return '🏋️';
      case 'leg': return '🦵';
      case 'core': return '💪';
      case 'posture': return '🧍';
      case 'neck': return '🧘';
      case 'breathing': return '🌬️';
      case 'yoga': return '🧘‍♀️';
      case 'stretching': return '🙆';
      case 'advanced': return '🔥';
      case 'balance': return '⚖️';
      case 'fascia': return '🔬';
      case 'shoulder': return '🔄';
      default: return '🏃';
    }
  }

  @override
  List<Object?> get props => [
    id, category, durationSeconds, setsCount,
    restSeconds, videoUrl, difficultyLevel,
  ];
}

/// Sleep log — Blueprint §7.2
class SleepLog extends Equatable {
  final String id;
  final DateTime date;
  final TimeOfDay bedTime;
  final TimeOfDay wakeTime;
  final double totalHours;
  final int? quality; // 1-5

  const SleepLog({
    required this.id,
    required this.date,
    required this.bedTime,
    required this.wakeTime,
    required this.totalHours,
    this.quality,
  });

  @override
  List<Object?> get props => [id, date, totalHours, quality];
}

/// Meal log — Blueprint §7.3
class MealLog extends Equatable {
  final String id;
  final DateTime date;
  final String mealType; // breakfast, lunch, dinner, snack
  final String description;
  final int? calories;
  final double? proteinG;
  final double? calciumMg;
  final double? vitaminDIU;
  final DateTime? aiAnalyzedAt;

  const MealLog({
    required this.id,
    required this.date,
    required this.mealType,
    required this.description,
    this.calories,
    this.proteinG,
    this.calciumMg,
    this.vitaminDIU,
    this.aiAnalyzedAt,
  });

  @override
  List<Object?> get props => [id, date, mealType, calories];
}

/// Height measurement — Blueprint §7.1
class HeightMeasurement extends Equatable {
  final String id;
  final double valueCm;
  final DateTime date;
  final String source; // manual, ar_scan
  final String? note;

  const HeightMeasurement({
    required this.id,
    required this.valueCm,
    required this.date,
    this.source = 'manual',
    this.note,
  });

  @override
  List<Object?> get props => [id, valueCm, date, source];
}

/// Training day completion — Blueprint §7.6
class TrainingDay extends Equatable {
  final DateTime date;
  final List<String> completedExerciseIds;
  final bool isComplete;

  const TrainingDay({
    required this.date,
    required this.completedExerciseIds,
    this.isComplete = false,
  });

  @override
  List<Object?> get props => [date, completedExerciseIds, isComplete];
}
