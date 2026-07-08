import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/ads/ad_service.dart';
import '../../../../core/services/user_data_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../providers/onboarding_provider.dart';

/// Final onboarding screen — "Your 90-Day Growth Plan is ready"
class YourPlanScreen extends ConsumerStatefulWidget {
  const YourPlanScreen({super.key});

  @override
  ConsumerState<YourPlanScreen> createState() => _YourPlanScreenState();
}

class _YourPlanScreenState extends ConsumerState<YourPlanScreen> {
  bool _isGenerating = false;

  Future<void> _generateReport() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    final onboardingData = ref.read(onboardingProvider);
    if (onboardingData != null) {
      final userDataService = ref.read(userDataServiceProvider);
      final persisted = PersistedUserData(
        name: onboardingData.name,
        gender: onboardingData.gender,
        birthYear: onboardingData.birthDate.year,
        birthMonth: onboardingData.birthDate.month,
        currentHeightCm: onboardingData.currentHeightCm,
        currentWeightKg: onboardingData.currentWeightKg,
        fatherHeightCm: onboardingData.fatherHeightCm,
        motherHeightCm: onboardingData.motherHeightCm,
        activityLevel: onboardingData.activityLevel,
        averageSleepHours: onboardingData.averageSleepHours,
        analysisDepth: onboardingData.analysisDepth,
        targetHeightCm: onboardingData.targetHeightCm,
        activityDaysPerWeek: onboardingData.activityDaysPerWeek,
      );
      await userDataService.saveUserData(persisted);
      await userDataService.addHeightMeasurement(onboardingData.currentHeightCm);
      await userDataService.savePlanStartDate(DateTime.now());
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingComplete, true);

    AnalyticsService().logOnboardingCompleted();

    final adService = ref.read(adServiceProvider);
    await adService.loadInterstitialAd();

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 800));

    // Schedule all notifications now that onboarding is complete
    final notifService = ref.read(notificationServiceProvider);
    await notifService.scheduleAllAfterOnboarding();

    if (!mounted) return;
    final shown = await adService.showInterstitialAd();
    if (!shown) {
      debugPrint('Interstitial ad not ready — proceeding without ad');
    }

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    context.go('/main');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D0A5E), Color(0xFF4C1D95)],
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingXl),
            child: Column(
              children: [
                const Spacer(),

                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.celebration_rounded,
                    size: 56,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  "Your 90-Day Growth Plan\nis Ready! 🎉",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  "We've analyzed your data and created a personalized plan "
                  "with daily exercises, nutrition guidance, and sleep optimization.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                _HighlightRow(icon: '🏋️', text: 'Daily exercise routines'),
                const SizedBox(height: 12),
                _HighlightRow(icon: '🥗', text: 'Personalized meal plans'),
                const SizedBox(height: 12),
                _HighlightRow(icon: '💤', text: 'Sleep optimization tips'),
                const SizedBox(height: 12),
                _HighlightRow(icon: '📊', text: 'Progress tracking & charts'),
                const SizedBox(height: 12),
                _HighlightRow(icon: '🤖', text: 'AI coach for questions'),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : _generateReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.accentDark,
                    ),
                    child: _isGenerating
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.accentDark),
                          )
                        : const Text(
                            'Generate My Report',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  '100% Free • Ad-Supported',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),

                const SizedBox(height: AppConstants.spacingSection),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  final String icon;
  final String text;

  const _HighlightRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}
