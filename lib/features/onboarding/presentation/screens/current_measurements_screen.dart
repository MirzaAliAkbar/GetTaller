import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/onboarding_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';

class CurrentMeasurementsScreen extends ConsumerStatefulWidget {
  const CurrentMeasurementsScreen({super.key});

  @override
  ConsumerState<CurrentMeasurementsScreen> createState() => _CurrentMeasurementsScreenState();
}

class _CurrentMeasurementsScreenState extends ConsumerState<CurrentMeasurementsScreen> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  bool _isMetric = true;

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _submit() {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    if (height == null || weight == null) return;

    final heightCm = _isMetric ? height : height * 2.54;
    final weightKg = _isMetric ? weight : weight * 0.453592;

    ref.read(onboardingProvider.notifier).setMeasurements(
      heightCm: heightCm,
      weightKg: weightKg,
    );
    context.go('/onboarding/parent-height');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingXl),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressBar(3, 13),
                const SizedBox(height: AppConstants.spacingXxl),
                Text("Your current measurements",
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: AppConstants.spacingSm),
                Text("We need your height and weight to calculate your BMI and growth potential.",
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppConstants.spacingXxl),

                // Unit toggle
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isMetric = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: _isMetric ? AppTheme.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _isMetric ? AppTheme.accent : AppTheme.textTertiary),
                        ),
                        child: Text('Metric', style: TextStyle(
                          color: _isMetric ? Colors.white : AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        )),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _isMetric = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isMetric ? AppTheme.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: !_isMetric ? AppTheme.accent : AppTheme.textTertiary),
                        ),
                        child: Text('Imperial', style: TextStyle(
                          color: !_isMetric ? Colors.white : AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        )),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingXxl),

                TextField(
                  controller: _heightController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _isMetric ? 'Height (cm)' : 'Height (inches)',
                    prefixIcon: const Icon(Icons.height_rounded),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingLg),
                TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _isMetric ? 'Weight (kg)' : 'Weight (lbs)',
                    prefixIcon: const Icon(Icons.monitor_weight_rounded),
                  ),
                ),

                const SizedBox(height: AppConstants.spacingXxl),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Continue'),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom + AppConstants.spacingLg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(int current, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step $current of $total', style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: current / total,
            backgroundColor: AppTheme.accent.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
