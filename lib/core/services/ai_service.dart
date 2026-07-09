import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_data_service.dart';
import 'remote_config_service.dart';
import '../utils/height_calculator.dart';

class AiService {
  static final AiService _instance = AiService._();
  factory AiService() => _instance;
  AiService._();

  // OpenCode Zen API Configuration (DeepSeek V4 Flash Free model)
  static const _baseUrl = 'https://opencode.ai/zen/v1/chat/completions';
  static const _model = 'deepseek-v4-flash-free';

  // Build-time fallback API key (for development/testing)
  static const _buildTimeApiKey = String.fromEnvironment('OPENCODE_ZEN_API_KEY');

  // Runtime-injected from Remote Config (for production)
  late String _runtimeApiKey;

  static const _systemPrompt = 'You are GetTaller AI Coach, an expert in height growth, '
      'nutrition, sleep optimization, exercise science, and adolescent development. '
      'You have access to the user\'s personal data — use it to give personalized advice. '
      'Reference their specific meals, sleep, height history, and plan progress in your answers. '
      'Be concise but thorough. Use emojis sparingly for emphasis. '
      'Always remind users that results require consistency with their 90-day plan. '
      'If the user is a teenager (13-19), emphasize urgency and consistency for their "Peak Potential". '
      'If the user is an adult (25+), focus on posture restoration and spinal health. '
      'If asked about medical conditions, advise consulting a doctor.';

  /// Initialize AI service with OpenCode Zen API key from Remote Config (production)
  Future<void> initialize() async {
    try {
      final remoteConfig = RemoteConfigService();
      _runtimeApiKey = remoteConfig.getOpenCodeZenApiKey();
      if (_runtimeApiKey.isEmpty) {
        _runtimeApiKey = _buildTimeApiKey; // Fallback to build-time key
      }
    } catch (e) {
      print('Failed to load OpenCode Zen API key from Remote Config: $e');
      _runtimeApiKey = _buildTimeApiKey; // Fallback to build-time key
    }
  }

  /// Get the appropriate API key (Remote Config or build-time fallback)
  String _getApiKey() {
    return _runtimeApiKey.isNotEmpty ? _runtimeApiKey : _buildTimeApiKey;
  }

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
      buffer.writeln('- Predicted potential: ${predicted.peakHeight.toStringAsFixed(1)} cm');
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

      // OpenCode Zen API call (DeepSeek V4 Flash - NO THINKING MODE)
      // Optimized for fast, direct responses
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_getApiKey()}',
        },
        body: jsonEncode({
          'model': _model, // deepseek-v4-flash-free (no thinking)
          'messages': [
            {'role': 'system', 'content': systemMsg},
            {'role': 'user', 'content': question},
          ],
          'max_tokens': 512, // Reduced for concise answers
          'temperature': 0.5, // Lower for focused, direct responses
          'thinking': false, // Explicitly disable thinking mode
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['choices'][0]['message'];

        // Get direct answer (no thinking/reasoning content)
        var answer = (message['content'] ?? '').toString().trim();

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
