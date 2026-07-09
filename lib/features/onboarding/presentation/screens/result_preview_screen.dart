import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/onboarding_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/height_calculator.dart';
import '../../../../shared/widgets/banner_ad_widget.dart';

class ResultPreviewScreen extends ConsumerWidget {
  const ResultPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(onboardingProvider);
    if (data == null) return const Scaffold(body: Center(child: Text('No data')));

    final predicted = HeightCalculator.calculateAdjustedPrediction(
      fatherHeightCm: data.fatherHeightCm,
      motherHeightCm: data.motherHeightCm,
      isMale: data.isMale,
      currentHeightCm: data.currentHeightCm,
      ageYears: data.ageYears,
      weightKg: data.currentWeightKg,
      averageSleepHours: data.averageSleepHours,
      activityDaysPerWeek: data.activityDaysPerWeek,
    );

    final potentialGain = HeightCalculator.calculateHeightGain(
      currentHeightCm: data.currentHeightCm,
      predictedHeightCm: predicted.peakHeight,
    );

    final completion = HeightCalculator.calculateGrowthCompletion(
      ageYears: data.ageYears,
      isMale: data.isMale,
      currentHeightCm: data.currentHeightCm,
      predictedHeightCm: predicted.peakHeight,
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PBar(9, 13),
              const SizedBox(height: AppConstants.spacingXxl),

              Text("Your Height Prediction",
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: AppConstants.spacingSm),
              Text("Based on your genetic profile and lifestyle factors.",
                  style: Theme.of(context).textTheme.bodyMedium),

              const SizedBox(height: AppConstants.spacingLg),

              // Current height
              Center(
                child: Column(
                  children: [
                    Text("Your Current Height",
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${data.currentHeightCm.toStringAsFixed(1)} cm',
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Arrow
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.arrow_downward_rounded,
                          color: AppTheme.accent, size: 24),
                    ),
                    const SizedBox(height: 24),

                    // Predicted height
                    Text("Your Projected Potential",
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${predicted.peakHeight.toStringAsFixed(1)} cm',
                      style: GoogleFonts.inter(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Potential gain badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.accent,
                            potentialGain > 3
                                ? AppTheme.energyOrange
                                : AppTheme.accentLight
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        potentialGain > 3
                            ? '🔥 ${potentialGain.toStringAsFixed(1)} cm potential gain!'
                            : '📈 ${potentialGain.toStringAsFixed(1)} cm potential gain',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Growth completion
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatBadge(
                          label: 'Growth Window Used',
                          value: '${(completion * 100).toStringAsFixed(0)}%',
                          color: completion > 0.7
                              ? AppTheme.error
                              : completion > 0.4
                                  ? AppTheme.warning
                                  : AppTheme.success,
                        ),
                        const SizedBox(width: 12),
                        _StatBadge(
                          label: 'Age',
                          value: '${data.ageYears} yrs',
                          color: AppTheme.info,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacingLg),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.go('/onboarding/your-plan'),
                  child: const Text('View My 90-Day Plan'),
                ),
              ),

              const SizedBox(height: 12),

              // Banner ad
              const BannerAdWidget(
                adUnitId: AppConstants.bannerResultPreviewAdUnitId,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label, value;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
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

class _PBar extends StatelessWidget {
  final int c, t;
  const _PBar(this.c, this.t);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step $c of $t',
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: c / t,
              backgroundColor: AppTheme.accent.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
              minHeight: 6,
            ),
          ),
        ],
      );
}
