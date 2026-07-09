import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/onboarding_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';

class SleepDurationScreen extends ConsumerStatefulWidget {
  const SleepDurationScreen({super.key});

  @override
  ConsumerState<SleepDurationScreen> createState() => _SleepDurationScreenState();
}

class _SleepDurationScreenState extends ConsumerState<SleepDurationScreen> {
  double _hours = 7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.pop())),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingXl),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _progressBar(6, 13),
            const SizedBox(height: AppConstants.spacingXxl),
            Text("How many hours do you sleep?", style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: AppConstants.spacingSm),
            Text("Sleep is when HGH (human growth hormone) is released. This is critical for growth.",
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppConstants.spacingXxl),
            Expanded(
              child: Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.sleepIndigo, Color(0xFF7C4DFF)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [BoxShadow(color: AppTheme.sleepIndigo.withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 10))],
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('${_hours.toInt()}', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w700, color: Colors.white)),
                      const Text('hours', style: TextStyle(fontSize: 18, color: Colors.white70)),
                    ]),
                  ),
                  const SizedBox(height: AppConstants.spacingXxl),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.sleepIndigo,
                      thumbColor: AppTheme.sleepIndigo,
                      overlayColor: AppTheme.sleepIndigo.withOpacity(0.1),
                      inactiveTrackColor: AppTheme.sleepIndigo.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: _hours, min: 3, max: 12, divisions: 9,
                      label: '${_hours.toInt()} hours',
                      onChanged: (v) => setState(() => _hours = v),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),
                  Text(_hours < 7 ? '⚠️ Under 7 hours may limit HGH production' : _hours >= 8
                      ? '✅ Optimal for HGH release' : '👍 Adequate',
                      style: TextStyle(
                        color: _hours < 7 ? AppTheme.error : _hours >= 8 ? AppTheme.success : AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      )),
                ]),
              ),
            ),
            SizedBox(width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(onboardingProvider.notifier).setSleepHours(_hours);
                  context.push('/onboarding/analysis-depth');
                },
                child: const Text('Continue'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _progressBar(int c, int t) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Step $c of $t', style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
    const SizedBox(height: 8),
    ClipRRect(borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(value: c / t, backgroundColor: AppTheme.accent.withOpacity(0.1),
          valueColor: const AlwaysStoppedAnimation(AppTheme.accent), minHeight: 6),
    ),
  ]);
}
