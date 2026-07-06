import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/height_calculator.dart';
import '../../../../core/services/user_data_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/height_growth_chart.dart';
import '../../../../shared/widgets/notification_permission_prompt.dart';

/// Dashboard tab — Blueprint §4.2
/// Shows growth data, chart, streak, and quick action cards.
class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  @override
  void initState() {
    super.initState();
    // Mark today visited for streak tracking + notification service
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userDataService = ref.read(userDataServiceProvider);
      final notifService = ref.read(notificationServiceProvider);

      await userDataService.markTodayVisited();
      await notifService.markTodayActive();

      // Check streak & fire applicable notifications
      final streak = await userDataService.getCurrentStreak();
      final completed = await userDataService.getCompletedLevels();

      // Streak milestone (3, 7, 14, 21, 30, 60, 90)
      final milestones = [3, 7, 14, 21, 30, 60, 90];
      if (milestones.contains(streak)) {
        await notifService.fireStreakMilestone(streak);
      }

      // Streak at risk? If streak > 0 and no workout done today
      if (streak > 0 && completed.isEmpty) {
        await notifService.fireStreakAtRisk(streak);
      }

      // Check re-engagement (7/14/30 days inactive)
      await notifService.fireReEngagement();

      // Goal proximity
      final userData = await userDataService.loadUserData();
      if (userData?.targetHeightCm != null && userData != null) {
        final remaining = userData.targetHeightCm! - userData.currentHeightCm;
        if (remaining > 0 && remaining <= 5) {
          await notifService.fireGoalProximity(remaining);
        }
      }

      // Show notification permission prompt on first visit
      if (await notifService.shouldShowPrompt()) {
        if (!context.mounted) return;
        await showNotificationPermissionPrompt(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userDataAsync = ref.watch(persistedUserDataProvider);
    final canMeasureAsync = ref.watch(canMeasureHeightProvider);
    final daysUntilNextAsync = ref.watch(daysUntilNextMeasurementProvider);
    final streakAsync = ref.watch(streakProvider);

    return Scaffold(
      body: SafeArea(
        child: userDataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Could not load data: $err')),
          data: (userData) {
            if (userData == null) {
              return _buildEmptyState(context);
            }
            return _buildDashboard(context, userData, canMeasureAsync, daysUntilNextAsync, streakAsync);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.height_rounded, size: 80, color: AppTheme.accent.withOpacity(0.3)),
            const SizedBox(height: 24),
            const Text(
              "Complete the onboarding\nto see your dashboard",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/onboarding/welcome'),
              child: const Text('Start Assessment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    PersistedUserData userData,
    AsyncValue<bool> canMeasureAsync,
    AsyncValue<int> daysUntilNextAsync,
    AsyncValue<int> streakAsync,
  ) {
    final predictedHeight = HeightCalculator.calculateAdjustedPrediction(
      fatherHeightCm: userData.fatherHeightCm,
      motherHeightCm: userData.motherHeightCm,
      isMale: userData.isMale,
      currentHeightCm: userData.currentHeightCm,
      ageYears: userData.ageYears,
      weightKg: userData.currentWeightKg,
      averageSleepHours: userData.averageSleepHours,
      activityDaysPerWeek: userData.activityDaysPerWeek,
    );

    final potentialGain = HeightCalculator.calculateHeightGain(
      currentHeightCm: userData.currentHeightCm,
      predictedHeightCm: predictedHeight,
    );

    final percentile = HeightCalculator.calculatePercentile(
      heightCm: userData.currentHeightCm,
      isMale: userData.isMale,
      ageYears: userData.ageYears,
    );

    final bmi = userData.currentWeightKg / ((userData.currentHeightCm / 100) * (userData.currentHeightCm / 100));

    final canMeasure = canMeasureAsync.asData?.value ?? false;
    final daysUntilNext = daysUntilNextAsync.asData?.value ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData.name != null && userData.name!.isNotEmpty
                          ? 'Welcome back, ${userData.name}!'
                          : 'Your Growth Journey',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      '${userData.ageYears} yrs old • ${userData.isMale ? "Male" : "Female"}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 36,
                child: IconButton(
                  icon: const Icon(Icons.school_outlined, size: 22),
                  tooltip: 'Education Hub',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () => context.push('/education'),
                ),
              ),
              const SizedBox(width: 2),
              SizedBox(
                height: 36,
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 22),
                  tooltip: 'Settings',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () => context.push('/settings'),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // Daily Score Card
          _ScoreCard(
            score: potentialGain > 0 ? 85 : 50,
            streak: streakAsync.asData?.value ?? 0,
            predictedGain: potentialGain,
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // Growth chart
          _SectionHeader(
            title: 'Growth Projection',
            action: 'View History',
            onTap: () => _showMeasurementHistory(context, userData),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Container(
            height: 220,
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            decoration: _cardDecoration(context),
            child: HeightGrowthChart(
              currentHeight: userData.currentHeightCm,
              predictedHeight: predictedHeight,
              ageYears: userData.ageYears,
              isMale: userData.isMale,
            ),
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // Height measurement card
          _HeightMeasureCard(
            currentHeightCm: userData.currentHeightCm,
            canMeasure: canMeasure,
            daysUntilNext: daysUntilNext,
            onMeasure: () => _addHeightMeasurement(context, userData),
            onHistory: () => _showMeasurementHistory(context, userData),
            predictedHeight: predictedHeight,
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Potential Gain',
                  value: '+${potentialGain.toStringAsFixed(1)} cm',
                  icon: Icons.trending_up_rounded,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Percentile',
                  value: '${(percentile * 100).toStringAsFixed(0)}th',
                  icon: Icons.leaderboard_rounded,
                  color: AppTheme.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'BMI',
                  value: bmi.toStringAsFixed(1),
                  icon: Icons.monitor_weight_rounded,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingXl),

          // Quick Actions
          _SectionHeader(title: 'Quick Actions', action: null),
          const SizedBox(height: AppConstants.spacingSm),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.restaurant_rounded,
                  label: 'Nutrition Tips',
                  color: AppTheme.energyOrange,
                  onTap: () => context.push('/education'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.bedtime_rounded,
                  label: 'Sleep Guide',
                  color: AppTheme.sleepIndigo,
                  onTap: () => context.push('/education'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.fitness_center_rounded,
                  label: 'Exercises',
                  color: AppTheme.accent,
                  onTap: () => context.push('/workout/spine_1'),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingXxl),
        ],
      ),
    );
  }

  void _addHeightMeasurement(BuildContext context, PersistedUserData userData) {
    final heightController = TextEditingController(
      text: userData.currentHeightCm.toStringAsFixed(1),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Log Your Height',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.info.withOpacity(0.12)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.science_rounded, size: 18, color: AppTheme.info),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bone remodeling cycles suggest measuring every 30 days '
                        'for accurate tracking. Consistent monthly measurements '
                        'help identify your true growth trend.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: heightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  suffixText: 'cm',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final value = double.tryParse(heightController.text);
                    if (value == null || value < 100 || value > 250) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid height (100-250 cm)')),
                      );
                      return;
                    }
                    final service = ref.read(userDataServiceProvider);
                    await service.addHeightMeasurement(value);
                    await service.updateCurrentHeight(value);

                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    setState(() {}); // Refresh

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Height logged! Check back in 30 days.'),
                        backgroundColor: AppTheme.accent,
                      ),
                    );
                  },
                  child: const Text('Save Measurement'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMeasurementHistory(BuildContext context, PersistedUserData userData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Height History',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ref.watch(heightMeasurementsProvider).when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (measurements) {
                        if (measurements.isEmpty) {
                          return const Center(child: Text('No measurements recorded yet'));
                        }
                        return ListView.builder(
                          controller: scrollController,
                          itemCount: measurements.length,
                          itemBuilder: (_, i) {
                            final m = measurements[measurements.length - 1 - i]; // newest first
                            final months = [
                              'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                            ];
                            final label = '${months[m.date.month - 1]} ${m.date.day}, ${m.date.year}';
                            final change = i == 0
                                ? null
                                : measurements[measurements.length - 1 - i].heightCm -
                                    measurements[measurements.length - 2 - i].heightCm;
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFF0F0F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.height_rounded, color: AppTheme.accent, size: 22),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${m.heightCm.toStringAsFixed(1)} cm',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                        ),
                                        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
                                      ],
                                    ),
                                  ),
                                  if (change != null && change != 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: change > 0
                                            ? AppTheme.accent.withOpacity(0.1)
                                            : AppTheme.error.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${change > 0 ? "+" : ""}${change.toStringAsFixed(1)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: change > 0 ? AppTheme.accent : AppTheme.error,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? AppTheme.surfaceDark : Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final int score;
  final int streak;
  final double predictedGain;

  const _ScoreCard({
    required this.score,
    required this.streak,
    required this.predictedGain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingXl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accent, AppTheme.accentDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Score circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$score',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spacingLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Height Score',
                    style: TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                  score >= 80 ? 'On track! 🔥' : 'Keep going! 💪',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.trending_up_rounded,
                        color: Colors.white.withOpacity(0.8), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${predictedGain.toStringAsFixed(1)} cm potential gain',
                      style: TextStyle(
                          fontSize: 13, color: Colors.white.withOpacity(0.9)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeightMeasureCard extends StatelessWidget {
  final double currentHeightCm;
  final bool canMeasure;
  final int daysUntilNext;
  final VoidCallback onMeasure;
  final VoidCallback onHistory;
  final double predictedHeight;

  const _HeightMeasureCard({
    required this.currentHeightCm,
    required this.canMeasure,
    required this.daysUntilNext,
    required this.onMeasure,
    required this.onHistory,
    required this.predictedHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.sleepIndigo.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.sleepIndigo.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: (canMeasure ? AppTheme.accent : AppTheme.textTertiary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.height_rounded,
                  color: canMeasure ? AppTheme.accent : AppTheme.textTertiary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${currentHeightCm.toStringAsFixed(1)} cm',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      canMeasure
                          ? 'Ready to log your height!'
                          : 'Next measurement in $daysUntilNext days',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              if (canMeasure)
                Container(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: onMeasure,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    child: const Text('Log'),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.history_rounded, size: 22),
                color: AppTheme.textTertiary,
                onPressed: onHistory,
                tooltip: 'View history',
              ),
            ],
          ),
          if (!canMeasure) ...[
            const SizedBox(height: 16),
            // Circular countdown
            Row(
              children: [
                SizedBox(
                  width: 56, height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 48, height: 48,
                        child: CircularProgressIndicator(
                          value: 1 - (daysUntilNext / 30),
                          backgroundColor: AppTheme.sleepIndigo.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation(AppTheme.sleepIndigo),
                          strokeWidth: 4,
                        ),
                      ),
                      Text(
                        '$daysUntilNext',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.sleepIndigo,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Waiting for bone remodeling cycle',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Measuring every 30 days gives reliable data. '
                        'Your target: ${predictedHeight.toStringAsFixed(1)} cm',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textTertiary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;

  const _SectionHeader({required this.title, this.action, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (action != null)
          GestureDetector(
            onTap: onTap,
            child: Text(action!,
                style: const TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w500,
                    fontSize: 13)),
          ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textTertiary)),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

