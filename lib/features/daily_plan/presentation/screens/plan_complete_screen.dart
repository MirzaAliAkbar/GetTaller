import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/user_data_service.dart';
import '../../../../core/utils/certificate_generator.dart';
import '../../../../core/utils/height_calculator.dart';
import '../../../../core/utils/unit_converter.dart';

class PlanCompleteScreen extends ConsumerStatefulWidget {
  const PlanCompleteScreen({super.key});

  @override
  ConsumerState<PlanCompleteScreen> createState() => _PlanCompleteScreenState();
}

class _PlanCompleteScreenState extends ConsumerState<PlanCompleteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.5, curve: Curves.easeOut)),
    );
    _scale = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.7, curve: Curves.elasticOut)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userDataAsync = ref.watch(persistedUserDataProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D0A5E), Color(0xFF4C1D95), Color(0xFF7C3AED)],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Opacity(
              opacity: _fadeIn.value,
              child: Transform.scale(
                scale: _scale.value,
                child: child,
              ),
            ),
            child: userDataAsync.when(
              data: (userData) {
                if (userData == null) {
                  return const Center(child: Text('No data', style: TextStyle(color: Colors.white)));
                }

                final userName = userData.name ?? '';
                final gender = userData.gender;
                final age = userData.ageYears;
                final currentHeight = userData.currentHeightCm;
                final fatherHeight = userData.fatherHeightCm;
                final motherHeight = userData.motherHeightCm;
                final weight = userData.currentWeightKg;
                final sleep = userData.averageSleepHours;
                final activity = userData.activityDaysPerWeek;

                final predicted = HeightCalculator.calculateAdjustedPrediction(
                  fatherHeightCm: fatherHeight,
                  motherHeightCm: motherHeight,
                  isMale: userData.isMale,
                  currentHeightCm: currentHeight,
                  ageYears: age,
                  weightKg: weight,
                  averageSleepHours: sleep,
                  activityDaysPerWeek: activity,
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // Trophy
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                        ),
                        child: const Icon(Icons.emoji_events_rounded, size: 50, color: Color(0xFFFFD700)),
                      ),

                      const SizedBox(height: 28),

                      Text(
                        'Journey Complete!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'You\'ve completed the full 90-Day Growth Program.\nHere\'s to your progress!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.75),
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Stats row
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatItem(label: 'Days', value: '90'),
                            _divider(),
                            _StatItem(label: 'Started', value: UnitConverter.formatHeight(currentHeight)),
                            _divider(),
                            _StatItem(label: 'Potential', value: UnitConverter.formatHeight(predicted.peakHeight)),
                          ],
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Download Certificate button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final service = ref.read(userDataServiceProvider);
                            final startDate = await service.getPlanStartDate();
                            await service.resetPlan();
                            if (!mounted) return;
                            await CertificateGenerator.generateAndShare(
                              userName: userName,
                              gender: gender,
                              ageYears: age,
                              currentHeightCm: currentHeight,
                              predictedHeightCm: predicted.peakHeight,
                              startDate: startDate ?? DateTime.now().subtract(const Duration(days: 90)),
                              endDate: DateTime.now(),
                            );
                          },
                          icon: const Icon(Icons.download_rounded, size: 20),
                          label: const Text('Download Certificate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.accentDark,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Start New Prediction button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final service = ref.read(userDataServiceProvider);
                            await service.resetPlan();
                            if (!mounted) return;
                            context.go('/onboarding/gender');
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          label: const Text('Start New Prediction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Keep Going button
                      TextButton(
                        onPressed: () => context.go('/main'),
                        child: Text(
                          'Keep Going',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
              error: (_, __) => const Center(child: Text('Error', style: TextStyle(color: Colors.white))),
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withOpacity(0.15),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
      ],
    );
  }
}
