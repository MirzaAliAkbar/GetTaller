import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/onboarding_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../shared/widgets/scroll_picker.dart';

class ParentHeightScreen extends ConsumerStatefulWidget {
  const ParentHeightScreen({super.key});

  @override
  ConsumerState<ParentHeightScreen> createState() => _ParentHeightScreenState();
}

class _ParentHeightScreenState extends ConsumerState<ParentHeightScreen> {
  late bool _isMetric;
  int _fatherHeightCm = 175;
  int _fatherFeet = 5;
  int _fatherInches = 9;
  int _motherHeightCm = 163;
  int _motherFeet = 5;
  int _motherInches = 4;

  @override
  void initState() {
    super.initState();
    _isMetric = UnitConverter.isMetric;
  }

  void _submit() {
    final fatherCm = _isMetric
        ? _fatherHeightCm.toDouble()
        : (_fatherFeet * 12 + _fatherInches) * 2.54;
    final motherCm = _isMetric
        ? _motherHeightCm.toDouble()
        : (_motherFeet * 12 + _motherInches) * 2.54;

    ref.read(onboardingProvider.notifier).setParentHeights(
      fatherHeightCm: fatherCm,
      motherHeightCm: motherCm,
    );
    context.go('/onboarding/sports');
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _progressBar(4, 13),
              const SizedBox(height: AppConstants.spacingXxl),
              Text("Your parents' height", style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: AppConstants.spacingSm),
              Text("This is the most important factor for predicting your height potential.",
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppConstants.spacingLg),

              // Unit toggle
              Row(
                children: [
                  _unitButton('Metric (cm)', true),
                  const SizedBox(width: 8),
                  _unitButton('Imperial (ft/in)', false),
                ],
              ),
              const SizedBox(height: AppConstants.spacingLg),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Father's height
                      _sectionLabel("Father's Height"),
                      const SizedBox(height: 8),
                      _isMetric
                          ? _buildMetricPicker(_fatherHeightCm, (i) => setState(() => _fatherHeightCm = 140 + i), 140)
                          : _buildImperialPicker(_fatherFeet, _fatherInches,
                              (f) => setState(() => _fatherFeet = 4 + f),
                              (i) => setState(() => _fatherInches = i),
                              _fatherFeet - 4, _fatherInches),
                      const SizedBox(height: AppConstants.spacingLg),

                      // Mother's height
                      _sectionLabel("Mother's Height"),
                      const SizedBox(height: 8),
                      _isMetric
                          ? _buildMetricPicker(_motherHeightCm, (i) => setState(() => _motherHeightCm = 140 + i), 140)
                          : _buildImperialPicker(_motherFeet, _motherInches,
                              (f) => setState(() => _motherFeet = 4 + f),
                              (i) => setState(() => _motherInches = i),
                              _motherFeet - 4, _motherInches),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.spacingLg),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.accent : AppTheme.textTertiary.withOpacity(0.3),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? [
            BoxShadow(
              color: AppTheme.accent.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              metric ? Icons.straighten_rounded : Icons.height_rounded,
              size: 16,
              color: selected ? Colors.white : AppTheme.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(
              color: selected ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.3,
            )),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(label.toUpperCase(), style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textTertiary,
          letterSpacing: 1.5,
        )),
      ],
    );
  }

  Widget _buildMetricPicker(int currentValue, ValueChanged<int> onChanged, int startValue) {
    final items = List.generate(81, (i) => '${startValue + i} cm');
    return ScrollPicker(
      items: items,
      initialIndex: currentValue - startValue,
      onSelected: onChanged,
    );
  }

  Widget _buildImperialPicker(int feet, int inches, ValueChanged<int> onFeetChanged,
      ValueChanged<int> onInchesChanged, int initialFeetIndex, int initialInchesIndex) {
    final feetItems = List.generate(4, (i) => '${4 + i} ft');
    final inchItems = List.generate(12, (i) => '$i in');
    return DualScrollPicker(
      leftItems: feetItems,
      rightItems: inchItems,
      initialLeftIndex: initialFeetIndex,
      initialRightIndex: initialInchesIndex,
      leftLabel: 'Feet',
      rightLabel: 'Inches',
      onLeftChanged: onFeetChanged,
      onRightChanged: onInchesChanged,
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
