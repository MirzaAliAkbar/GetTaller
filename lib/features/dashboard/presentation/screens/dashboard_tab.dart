import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../core/utils/height_calculator.dart';
import '../../../../core/services/user_data_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../shared/widgets/height_growth_chart.dart';
import '../../../../shared/widgets/notification_permission_prompt.dart';
import '../widgets/growth_window_timer.dart';
import '../../../daily_plan/presentation/providers/weekly_summary_providers.dart';
import '../../../premium/presentation/widgets/premium_banner.dart';
import 'package:in_app_review/in_app_review.dart';

/// Dashboard tab — Blueprint §4.2
/// Shows growth data, chart, streak, and quick action cards.
/// Design: ui-ux-pro-max health/wellness style, 60/30/10 color rule.
class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView('dashboard');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userDataService = ref.read(userDataServiceProvider);
      final notifService = ref.read(notificationServiceProvider);

      await userDataService.markTodayVisited();
      await notifService.markTodayActive();

      final streak = await userDataService.getCurrentStreak();
      final completed = await userDataService.getCompletedLevels();

      final milestones = [3, 7, 14, 21, 30, 60, 90];
      if (milestones.contains(streak)) {
        await notifService.fireStreakMilestone(streak);
        if (streak == 7) _requestAppReview();
      }

      if (streak > 0 && completed.isEmpty) {
        await notifService.fireStreakAtRisk(streak);
      }

      await notifService.fireReEngagement();

      final userData = await userDataService.loadUserData();
      if (userData?.targetHeightCm != null && userData != null) {
        final remaining = userData.targetHeightCm! - userData.currentHeightCm;
        if (remaining > 0 && remaining <= 5) {
          await notifService.fireGoalProximity(remaining);
        }
      }

      if (await notifService.shouldShowPrompt()) {
        if (!context.mounted) return;
        await showNotificationPermissionPrompt(context);
      }
    });
  }

  Future<void> _requestAppReview() async {
    final inAppReview = InAppReview.instance;
    try {
      if (await inAppReview.isAvailable()) {
        inAppReview.requestReview();
      }
    } catch (e) {
      debugPrint('Error requesting review: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userDataAsync = ref.watch(persistedUserDataProvider);
    final canMeasureAsync = ref.watch(canMeasureHeightProvider);
    final daysUntilNextAsync = ref.watch(daysUntilNextMeasurementProvider);
    final streakAsync = ref.watch(streakProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: userDataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Could not load data: $err')),
          data: (userData) {
            if (userData == null) return _buildEmptyState(context);
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.height_rounded, size: 48, color: AppTheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              "Complete the onboarding\nto see your dashboard",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => context.go('/onboarding/welcome'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Start Assessment', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
              ),
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
    final predictionResult = HeightCalculator.calculateAdjustedPrediction(
      fatherHeightCm: userData.fatherHeightCm,
      motherHeightCm: userData.motherHeightCm,
      isMale: userData.isMale,
      currentHeightCm: userData.currentHeightCm,
      ageYears: userData.ageYears,
      weightKg: userData.currentWeightKg,
      averageSleepHours: userData.averageSleepHours,
      activityDaysPerWeek: userData.activityDaysPerWeek,
    );

    final predictedHeight = predictionResult.peakHeight;
    final potentialGain = HeightCalculator.calculateHeightGain(
      currentHeightCm: userData.currentHeightCm,
      predictedHeightCm: predictedHeight,
    );
    final percentile = HeightCalculator.calculateAgeAdjustedPercentile(
      heightCm: userData.currentHeightCm,
      isMale: userData.isMale,
      ageYears: userData.ageYears,
    );
    final bmi = userData.currentWeightKg / ((userData.currentHeightCm / 100) * (userData.currentHeightCm / 100));
    final canMeasure = canMeasureAsync.asData?.value ?? false;
    final daysUntilNext = daysUntilNextAsync.asData?.value ?? 0;
    final showRecapBadge = ref.watch(weeklyRecapBadgeProvider).asData?.value ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          _buildHeader(context, userData, showRecapBadge),

          const SizedBox(height: 4),

          // ── Premium Banner ──
          const PremiumBanner(),

          const SizedBox(height: 16),

          // ── Growth Window Timer ──
          GrowthWindowTimer(
            ageYears: userData.ageYears,
            birthYear: userData.birthYear,
            birthMonth: userData.birthMonth,
          ),

          const SizedBox(height: 20),

          // ── Hero Metrics (Current + Peak) ──
          _HeroMetricRow(
            currentHeight: userData.currentHeightCm,
            peakHeight: predictedHeight,
          ),

          const SizedBox(height: 20),

          // ── Height Card ──
          _HeightCard(
            currentHeightCm: userData.currentHeightCm,
            canMeasure: canMeasure,
            daysUntilNext: daysUntilNext,
            onMeasure: () => _addHeightMeasurement(context, userData),
            onHistory: () => _showMeasurementHistory(context, userData),
            predictedHeight: predictedHeight,
            percentile: percentile,
            ageYears: userData.ageYears,
          ),

          const SizedBox(height: 20),

          // ── Growth Chart ──
          _buildChartSection(context, userData, predictedHeight),

          const SizedBox(height: 20),

          // ── Stats Row ──
          _StatsRow(
            potentialGain: potentialGain,
            percentile: percentile,
            bmi: bmi,
          ),

          const SizedBox(height: 24),

          // ── Quick Actions ──
          _QuickActionsSection(
            onNutrition: () => context.push('/education'),
            onSleep: () => context.push('/education'),
            onExercises: () => context.push('/main', extra: 1),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PersistedUserData userData, bool showRecapBadge) {
    final greeting = _getGreeting();
    final name = (userData.name != null && userData.name!.isNotEmpty) ? userData.name! : '';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          // Greeting + name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? '$greeting, $name!' : 'Your Growth Journey',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${userData.ageYears} yrs • ${userData.isMale ? "Male" : "Female"}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Action buttons — clean, minimal
          if (showRecapBadge)
            _HeaderIconButton(
              icon: Icons.insights_rounded,
              badge: true,
              tooltip: 'Weekly Recap',
              onTap: () async {
                await markWeeklyRecapViewed();
                ref.invalidate(weeklyRecapBadgeProvider);
                if (context.mounted) context.push('/weekly-recap');
              },
            ),
          _HeaderIconButton(
            icon: Icons.info_outline_rounded,
            tooltip: 'Science Info',
            onTap: () => _showScienceInfo(context),
          ),
          _HeaderIconButton(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildChartSection(BuildContext context, PersistedUserData userData, double predictedHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Growth Projection',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => _showMeasurementHistory(context, userData),
              child: Text(
                'View History',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: HeightGrowthChart(
            currentHeight: userData.currentHeightCm,
            predictedHeight: predictedHeight,
            ageYears: userData.ageYears,
            isMale: userData.isMale,
          ),
        ),
      ],
    );
  }

  void _showScienceInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Scientific Methodology', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GetTaller uses a multi-stage calculation engine based on established growth models:',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 12),
              _ScienceItem('Mid-Parental Height (Tanner)', 'Predicts genetic target height using parental measurements.'),
              _ScienceItem('Khamis-Roche Model', 'Factors in current height and weight momentum for teens.'),
              _ScienceItem('Environmental Optimization', 'Models the impact of HGH release during deep sleep, nutritional availability, and spinal decompression.'),
              const SizedBox(height: 12),
              Text(
                'Note: All predictions include a motivational adjustment and assume strict adherence to the 90-day plan.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('I Understand', style: GoogleFonts.plusJakartaSans(color: AppTheme.primary)),
          ),
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
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log Your Height',
                style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700),
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
                        'Bone remodeling cycles suggest measuring every 30 days for accurate tracking.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: heightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Height (${UnitConverter.heightUnit()})',
                  suffixText: UnitConverter.heightUnit(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final value = double.tryParse(heightController.text);
                    if (value == null || value < 100 || value > 250) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Please enter a valid height (100-250 ${UnitConverter.heightUnit()})')),
                      );
                      return;
                    }
                    final cmValue = UnitConverter.inputToCm(value);
                    final service = ref.read(userDataServiceProvider);
                    await service.addHeightMeasurement(cmValue);
                    await service.updateCurrentHeight(cmValue);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    setState(() {});
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Height logged! Check back in 30 days.')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Save Measurement', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
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
                      Text(
                        'Height History',
                        style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700),
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
                          return Center(
                            child: Text('No measurements recorded yet', style: GoogleFonts.plusJakartaSans(color: AppTheme.textTertiary)),
                          );
                        }
                        return ListView.builder(
                          controller: scrollController,
                          itemCount: measurements.length,
                          itemBuilder: (_, i) {
                            final m = measurements[measurements.length - 1 - i];
                            final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
                                  const Icon(Icons.height_rounded, color: AppTheme.primary, size: 22),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          UnitConverter.formatHeight(m.heightCm),
                                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 16),
                                        ),
                                        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textTertiary)),
                                      ],
                                    ),
                                  ),
                                  if (change != null && change != 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: change > 0
                                            ? AppTheme.success.withOpacity(0.1)
                                            : AppTheme.error.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${change > 0 ? "+" : ""}${change.toStringAsFixed(1)}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: change > 0 ? AppTheme.success : AppTheme.error,
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
}

// ── Clean Header Icon Button ──
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool badge;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: SizedBox(
        width: 40,
        height: 40,
        child: IconButton(
          icon: badge
              ? Badge(
                  smallSize: 7,
                  backgroundColor: AppTheme.energyOrange,
                  child: Icon(icon, size: 21, color: AppTheme.textSecondary),
                )
              : Icon(icon, size: 21, color: AppTheme.textSecondary),
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          onPressed: onTap,
        ),
      ),
    );
  }
}

// ── Hero Metric Row (Current + Peak Potential) ──
class _HeroMetricRow extends StatelessWidget {
  final double currentHeight;
  final double peakHeight;

  const _HeroMetricRow({required this.currentHeight, required this.peakHeight});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Current height — light card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppTheme.textTertiary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      UnitConverter.formatHeight(currentHeight).split(' ').first,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      UnitConverter.heightUnit(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Peak potential — gradient accent card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PEAK POTENTIAL',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      UnitConverter.formatHeight(peakHeight).split(' ').first,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      UnitConverter.heightUnit(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Height Card ──
class _HeightCard extends StatelessWidget {
  final double currentHeightCm;
  final bool canMeasure;
  final int daysUntilNext;
  final VoidCallback onMeasure;
  final VoidCallback onHistory;
  final double predictedHeight;
  final double percentile;
  final int ageYears;

  const _HeightCard({
    required this.currentHeightCm,
    required this.canMeasure,
    required this.daysUntilNext,
    required this.onMeasure,
    required this.onHistory,
    required this.predictedHeight,
    required this.percentile,
    required this.ageYears,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (canMeasure ? AppTheme.primary : AppTheme.textTertiary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.height_rounded,
                  color: canMeasure ? AppTheme.primary : AppTheme.textTertiary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      UnitConverter.formatHeight(currentHeightCm),
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ageYears >= 21
                          ? 'Taller than ${(percentile * 100).toStringAsFixed(0)}% of the world'
                          : 'Taller than ${(percentile * 100).toStringAsFixed(0)}% of people your age',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (canMeasure)
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: onMeasure,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Log'),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.history_rounded, size: 20),
                color: AppTheme.textTertiary,
                onPressed: onHistory,
                tooltip: 'View history',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Percentile bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentile.clamp(0.01, 1.0),
              backgroundColor: AppTheme.primary.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation(AppTheme.primary.withOpacity(0.5)),
              minHeight: 5,
            ),
          ),
          // Countdown when not measurable
          if (!canMeasure) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                SizedBox(
                  width: 48, height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 42, height: 42,
                        child: CircularProgressIndicator(
                          value: 1 - (daysUntilNext / 30),
                          backgroundColor: AppTheme.primary.withOpacity(0.08),
                          valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                          strokeWidth: 3.5,
                        ),
                      ),
                      Text(
                        '$daysUntilNext',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Waiting for bone remodeling',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Target: ${UnitConverter.formatHeight(predictedHeight)}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textTertiary),
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

// ── Stats Row ──
class _StatsRow extends StatelessWidget {
  final double potentialGain;
  final double percentile;
  final double bmi;

  const _StatsRow({required this.potentialGain, required this.percentile, required this.bmi});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatTile(
          label: 'Potential Gain',
          value: '+${UnitConverter.formatHeight(potentialGain)}',
          icon: Icons.trending_up_rounded,
          color: AppTheme.primary,
        ),
        const SizedBox(width: 10),
        _StatTile(
          label: 'Percentile',
          value: '${(percentile * 100).toStringAsFixed(0)}th',
          icon: Icons.leaderboard_rounded,
          color: AppTheme.info,
        ),
        const SizedBox(width: 10),
        _StatTile(
          label: 'BMI',
          value: bmi.toStringAsFixed(1),
          icon: Icons.monitor_weight_rounded,
          color: AppTheme.success,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _StatTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textTertiary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Actions ──
class _QuickActionsSection extends StatelessWidget {
  final VoidCallback onNutrition;
  final VoidCallback onSleep;
  final VoidCallback onExercises;

  const _QuickActionsSection({required this.onNutrition, required this.onSleep, required this.onExercises});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.restaurant_rounded,
                label: 'Nutrition',
                color: AppTheme.energyOrange,
                onTap: onNutrition,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.bedtime_rounded,
                label: 'Sleep',
                color: AppTheme.sleepIndigo,
                onTap: onSleep,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.fitness_center_rounded,
                label: 'Exercises',
                color: AppTheme.primary,
                onTap: onExercises,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Science Info Item ──
class _ScienceItem extends StatelessWidget {
  final String title;
  final String description;

  const _ScienceItem(this.title, this.description);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $title',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              description,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
