import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/onboarding_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/unit_converter.dart';

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
  void initState() {
    super.initState();
    _isMetric = UnitConverter.isMetric;
  }

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

    UnitConverter.setMetric(_isMetric);

    ref.read(onboardingProvider.notifier).setMeasurements(
      heightCm: heightCm,
      weightKg: weightKg,
    );
    context.push('/onboarding/parent-height');
  }

  @override
  Widget build(BuildContext context) {
    final heightUnit = UnitConverter.heightUnit();
    final weightUnit = UnitConverter.weightUnit();
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
                  _unitButton('Metric', true),
                  const SizedBox(width: 8),
                  _unitButton('Imperial', false),
                ],
              ),
              const SizedBox(height: AppConstants.spacingXxl),

              TextField(
                controller: _heightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Height ($heightUnit)',
                  prefixIcon: const Icon(Icons.height_rounded),
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Weight ($weightUnit)',
                  prefixIcon: const Icon(Icons.monitor_weight_rounded),
                ),
              ),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _unitButton(String label, bool metric) {
    final selected = _isMetric == metric;
    return GestureDetector(
      onTap: () => setState(() => _isMetric = metric),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.accent : AppTheme.textTertiary,
          ),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? Colors.white : AppTheme.textSecondary,
          fontWeight: FontWeight.w600,
        )),
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
