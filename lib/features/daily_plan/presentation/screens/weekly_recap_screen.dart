import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/weekly_summary_providers.dart';

class WeeklyRecapScreen extends ConsumerStatefulWidget {
  const WeeklyRecapScreen({super.key});

  @override
  ConsumerState<WeeklyRecapScreen> createState() => _WeeklyRecapScreenState();
}

class _WeeklyRecapScreenState extends ConsumerState<WeeklyRecapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _markRecapShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_recap_shown_date', DateTime.now().toIso8601String().split('T').first);
  }

  @override
  Widget build(BuildContext context) {
    final sleepAsync = ref.watch(weeklySleepSummaryProvider);
    final mealAsync = ref.watch(weeklyMealSummaryProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D0A5E), Color(0xFF4C1D95)],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Opacity(
              opacity: _fadeIn.value,
              child: child,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Header
                  Text(
                    '📊 Weekly Recap',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Here\'s how your week went',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Sleep Section
                  sleepAsync.when(
                    data: (data) => _buildSleepSection(data),
                    loading: () => const CircularProgressIndicator(color: Colors.white),
                    error: (_, __) => const SizedBox(),
                  ),

                  const SizedBox(height: 20),

                  // Nutrition Section
                  mealAsync.when(
                    data: (data) => _buildMealSection(data),
                    loading: () => const CircularProgressIndicator(color: Colors.white),
                    error: (_, __) => const SizedBox(),
                  ),

                  const SizedBox(height: 20),

                  // Progress Section
                  _buildProgressSection(),

                  const SizedBox(height: 32),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _markRecapShown();
                        if (mounted) context.go('/main');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.accentDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSleepSection(Map<String, dynamic> data) {
    final hasData = data['hasData'] as bool;
    final avgHours = (data['avgHours'] as num?)?.toDouble() ?? 0;
    final avgQuality = (data['avgQuality'] as num?)?.toDouble() ?? 0;
    final daysLogged = (data['daysLogged'] as num?)?.toInt() ?? 0;
    final missedDays = data['missedDays'] as List<String>;

    String rating;
    String insight;
    if (!hasData) {
      rating = 'No Data';
      insight = 'Log your sleep this week to see your recap!';
    } else if (avgHours >= 8 && avgQuality >= 4) {
      rating = 'Wonderful';
      insight = 'Your ${avgHours}h average with ${avgQuality.toStringAsFixed(1)}/5 quality '
          'supports optimal HGH release during deep sleep phases (N3). '
          'This is the ideal range for growth hormone pulsatile secretion.';
    } else if (avgHours >= 6) {
      rating = 'Good';
      insight = 'Your ${avgHours}h average is decent. Research shows 8-10h '
          'maximizes nocturnal GH pulses. Try adding 30-60 min to boost '
          'your deep sleep duration for better growth optimization.';
    } else {
      rating = 'Needs Work';
      insight = 'At ${avgHours}h average, you\'re below the optimal 8-10h range. '
          'Studies show <7h reduces growth velocity by 32%. Prioritize sleep '
          'to maximize HGH release during slow-wave sleep.';
    }

    return _buildCard(
      emoji: '💤',
      title: 'Sleep',
      rating: rating,
      ratingColor: avgHours >= 8 ? AppTheme.success : avgHours >= 6 ? AppTheme.warning : AppTheme.error,
      stats: hasData ? [
        _Stat('Avg Hours', '${avgHours}h'),
        _Stat('Avg Quality', '${avgQuality.toStringAsFixed(1)}/5'),
        _Stat('Days Logged', '$daysLogged/7'),
      ] : null,
      missedDays: missedDays,
      insight: insight,
    );
  }

  Widget _buildMealSection(Map<String, dynamic> data) {
    final hasData = data['hasData'] as bool;
    final avgCal = (data['avgCalories'] as num?)?.toInt() ?? 0;
    final avgProtein = (data['avgProtein'] as num?)?.toDouble() ?? 0;
    final daysLogged = (data['daysLogged'] as num?)?.toInt() ?? 0;
    final missedDays = data['missedDays'] as List<String>;

    String rating;
    String insight;
    if (!hasData) {
      rating = 'No Data';
      insight = 'Log your meals this week to see your nutrition recap!';
    } else if (avgProtein >= 80 && avgCal >= 1800) {
      rating = 'Excellent';
      insight = 'Your ${avgProtein}g/day protein intake supports mTOR pathway '
          'activation for chondrocyte proliferation. Combined with ${avgCal} '
          'calories, you\'re providing optimal substrates for IGF-1 synthesis.';
    } else if (avgProtein >= 50) {
      rating = 'On Track';
      insight = 'Your ${avgProtein}g/day protein is a good start. For height optimization, '
          'aim for 1.6-2.0g/kg bodyweight. Protein provides amino acids like '
          'L-arginine that enhance GH secretion.';
    } else {
      rating = 'Needs Attention';
      insight = 'At ${avgProtein}g/day protein, you\'re below optimal. Protein is '
          'essential for growth plate chondrogenesis. Aim for eggs, chicken, '
          'fish, and dairy to support your growth plan.';
    }

    return _buildCard(
      emoji: '🥗',
      title: 'Nutrition',
      rating: rating,
      ratingColor: avgProtein >= 80 ? AppTheme.success : avgProtein >= 50 ? AppTheme.warning : AppTheme.error,
      stats: hasData ? [
        _Stat('Avg Calories', '$avgCal kcal'),
        _Stat('Avg Protein', '${avgProtein}g'),
        _Stat('Days Logged', '$daysLogged/7'),
      ] : null,
      missedDays: missedDays,
      insight: insight,
    );
  }

  Widget _buildProgressSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          const Icon(Icons.trending_up_rounded, color: Color(0xFFFFD700), size: 32),
          const SizedBox(height: 12),
          Text(
            'Keep Going!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Consistency is key. Every day you log your sleep and meals, '
            'you\'re building data that helps your AI coach give better advice. '
            'Your 90-day plan is designed for steady progress.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String emoji,
    required String title,
    required String rating,
    required Color ratingColor,
    List<_Stat>? stats,
    required List<String> missedDays,
    required String insight,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text(title, style: GoogleFonts.plusJakartaSans(
                fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
              )),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ratingColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(rating, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: ratingColor,
                )),
              ),
            ],
          ),

          if (stats != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: stats.map((s) => Column(
                children: [
                  Text(s.value, style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
                  )),
                  const SizedBox(height: 4),
                  Text(s.label, style: TextStyle(
                    fontSize: 11, color: Colors.white.withOpacity(0.6),
                  )),
                ],
              )).toList(),
            ),
          ],

          if (missedDays.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No data for: ${missedDays.join(", ")}',
                      style: const TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          Text(insight, style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.65),
            height: 1.5,
          )),
        ],
      ),
    );
  }
}

class _Stat {
  final String label, value;
  const _Stat(this.label, this.value);
}
