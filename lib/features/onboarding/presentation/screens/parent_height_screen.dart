import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/onboarding_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/unit_converter.dart';

class ParentHeightScreen extends ConsumerStatefulWidget {
  const ParentHeightScreen({super.key});

  @override
  ConsumerState<ParentHeightScreen> createState() => _ParentHeightScreenState();
}

class _ParentHeightScreenState extends ConsumerState<ParentHeightScreen> {
  final _fatherController = TextEditingController();
  final _motherController = TextEditingController();
  late bool _isMetric;

  @override
  void initState() {
    super.initState();
    _isMetric = UnitConverter.isMetric;
  }

  @override
  void dispose() {
    _fatherController.dispose();
    _motherController.dispose();
    super.dispose();
  }

  void _submit() {
    final father = double.tryParse(_fatherController.text);
    final mother = double.tryParse(_motherController.text);
    if (father == null || mother == null) return;

    final fatherCm = _isMetric ? father : father * 2.54;
    final motherCm = _isMetric ? mother : mother * 2.54;

    ref.read(onboardingProvider.notifier).setParentHeights(
      fatherHeightCm: fatherCm,
      motherHeightCm: motherCm,
    );
    context.go('/onboarding/sports');
  }

  @override
  Widget build(BuildContext context) {
    final unit = UnitConverter.heightUnit();
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
              _progressBar(4, 13),
              const SizedBox(height: AppConstants.spacingXxl),
              Text("Your parents' height", style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: AppConstants.spacingSm),
              Text("This is the most important factor for predicting your height potential.",
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
                controller: _fatherController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Father's height ($unit)",
                  prefixIcon: const Icon(Icons.man_rounded),
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),
              TextField(
                controller: _motherController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Mother's height ($unit)",
                  prefixIcon: const Icon(Icons.woman_rounded),
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

  Widget _progressBar(int c, int t) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Step $c of $t', style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
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
