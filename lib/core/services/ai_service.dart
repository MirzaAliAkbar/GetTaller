import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_data_service.dart';
import '../utils/height_calculator.dart';

class AiService {
  static final AiService _instance = AiService._();
  factory AiService() => _instance;
  AiService._();

  static const _apiKey = 'sk-R4bWJSXBtCGAYYKInPD4ue4g5Gp32UIsosIje6d2hABTLxdG0bIjBfAKBBJUgWRc';
  static const _baseUrl = 'https://opencode.ai/zen/v1/chat/completions';
  static const _model = 'deepseek-v4-flash-free';

  static const _systemPrompt = 'You are GetTaller AI Coach, an expert in height growth, '
      'nutrition, sleep optimization, exercise science, and adolescent development. '
      'You have access to the user\'s personal data — use it to give personalized advice. '
      'Reference their specific meals, sleep, height history, and plan progress in your answers. '
      'Be concise but thorough. Use emojis sparingly for emphasis. '
      'Always remind users that results require consistency with their 90-day plan. '
      'If asked about medical conditions, advise consulting a doctor.';

  /// Build a context string from the user's data for personalized AI responses.
  Future<String> buildUserContext(UserDataService service) async {
    try {
      final user = await service.loadUserData();
      if (user == null) return '';

      final heights = await service.getHeightMeasurements();
      final meals = await service.getTodayMealEntries();
      final sleep = await service.getThisWeekSleepEntries();
      final completed = await service.getCompletedLevels();
      final day = await service.getCurrentDayNumber();

      final predicted = HeightCalculator.calculateAdjustedPrediction(
        fatherHeightCm: user.fatherHeightCm,
        motherHeightCm: user.motherHeightCm,
        isMale: user.isMale,
        currentHeightCm: user.currentHeightCm,
        ageYears: user.ageYears,
        weightKg: user.currentWeightKg,
        averageSleepHours: user.averageSleepHours,
        activityDaysPerWeek: user.activityDaysPerWeek,
      );

      final phaseName = _getPhaseName(day);

      final recentHeights = heights.length > 5
          ? heights.sublist(heights.length - 5)
          : heights;

      final buffer = StringBuffer();
      buffer.writeln('USER PROFILE:');
      buffer.writeln('- Name: ${user.name ?? "Unknown"}');
      buffer.writeln('- Gender: ${user.gender}, Age: ${user.ageYears} years');
      buffer.writeln('- Height: ${user.currentHeightCm} cm, Weight: ${user.currentWeightKg} kg');
      buffer.writeln('- BMI: ${(user.currentWeightKg / ((user.currentHeightCm / 100) * (user.currentHeightCm / 100))).toStringAsFixed(1)}');
      buffer.writeln('- Father: ${user.fatherHeightCm} cm, Mother: ${user.motherHeightCm} cm');
      buffer.writeln('- Activity: ${user.activityDaysPerWeek} days/week (${user.activityLevel})');
      buffer.writeln('- Avg sleep: ${user.averageSleepHours} hours/night');
      buffer.writeln('- Predicted potential: ${predicted.toStringAsFixed(1)} cm');
      buffer.writeln();

      buffer.writeln('PLAN PROGRESS:');
      buffer.writeln('- Day $day of 90 ($phaseName phase)');
      buffer.writeln('- Days completed: ${completed.length}');
      buffer.writeln('- Streak: active');
      buffer.writeln();

      if (recentHeights.isNotEmpty) {
        buffer.writeln('HEIGHT HISTORY (recent):');
        for (final h in recentHeights) {
          buffer.writeln('- ${h.date.toString().split(" ")[0]}: ${h.heightCm} cm');
        }
        buffer.writeln();
      }

      if (meals.isNotEmpty) {
        buffer.writeln('TODAY\'S MEALS:');
        for (final m in meals.take(5)) {
          buffer.writeln('- ${m.description} (${m.calories} cal, ${m.protein}g protein, ${m.calcium}mg calcium)');
        }
        buffer.writeln();
      } else {
        buffer.writeln('TODAY\'S MEALS: No meals logged today');
        buffer.writeln();
      }

      if (sleep.isNotEmpty) {
        buffer.writeln('THIS WEEK\'S SLEEP:');
        for (final s in sleep.take(7)) {
          buffer.writeln('- ${s.date.toString().split(" ")[0]}: ${s.hoursSlept}h (${s.quality}/5 quality, bed ${s.bedTime}, wake ${s.wakeTime})');
        }
        buffer.writeln();
      } else {
        buffer.writeln('THIS WEEK\'S SLEEP: No sleep data logged');
        buffer.writeln();
      }

      return buffer.toString();
    } catch (e) {
      return '';
    }
  }

  String _getPhaseName(int day) {
    if (day <= 28) return 'Foundation';
    if (day <= 56) return 'Progression';
    if (day <= 84) return 'Intensification';
    return 'Maintenance';
  }

  Future<String> getResponse(String question, {String? userContext}) async {
    try {
      final systemMsg = userContext != null && userContext.isNotEmpty
          ? '$_systemPrompt\n\nHere is the user\'s current data:\n$userContext'
          : _systemPrompt;

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemMsg},
            {'role': 'user', 'content': question},
          ],
          'max_tokens': 1024,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['choices'][0]['message'];
        var content = message['content'] ?? '';
        var reasoning = message['reasoning_content'] ?? '';
        // DeepSeek models prefix reasoning with "Thinking." — strip it
        reasoning = reasoning.replaceFirst(RegExp(r'^Thinking\.\s*\d*\.\s*'), '').trim();
        // Use content if available, otherwise fall back to cleaned reasoning
        final answer = content.trim().isNotEmpty ? content.trim() : reasoning;
        return answer.isNotEmpty
            ? answer
            : 'Sorry, I couldn\'t generate a response. Please try again.';
      } else {
        return 'API error (${response.statusCode}). Please try again later.';
      }
    } catch (e) {
      return 'Network error. Please check your connection and try again.';
    }
  }
}
