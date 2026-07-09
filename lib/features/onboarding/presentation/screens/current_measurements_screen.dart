import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/onboarding_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../shared/widgets/scroll_picker.dart';

class CurrentMeasurementsScreen extends ConsumerStatefulWidget {
  const CurrentMeasurementsScreen({super.key});

  @override
  ConsumerState<CurrentMeasurementsScreen> createState() => _CurrentMeasurementsScreenState();
}

class _CurrentMeasurementsScreenState extends ConsumerState<CurrentMeasurementsScreen> {
  bool _isMetric = true;
  int _selectedHeightCm = 170;
  int _selectedFeet = 5;
  int _selectedInches = 7;
  int _selectedWeightKg = 65;
  int _selectedWeightLbs = 143;

  // Get gender from onboarding data for defaults
  bool get _isMale {
    final data = ref.read(onboardingProvider);
    return data?.isMale ?? true;
  }

  @override
  void initState() {
    super.initState();
    // Set defaults based on gender
    if (_isMale) {
      _selectedHeightCm = 173;
      _selectedFeet = 5;
      _selectedInches = 7;
      _selectedWeightKg = 70;
      _selectedWeightLbs = 154;
    } else {
      _selectedHeightCm = 162;
      _selectedFeet = 5;
      _selectedInches = 4;
      _selectedWeightKg = 55;
      _selectedWeightLbs = 121;
    }
    // Start with saved preference
    _isMetric = UnitConverter.isMetric;
  }

  void _submit() {
    final heightCm = _isMetric
        ? _selectedHeightCm.toDouble()
        : (_selectedFeet * 12 + _selectedInches) * 2.54;
    final weightKg = _isMetric
        ? _selectedWeightKg.toDouble()
        : _selectedWeightLbs * 0.453592;

    UnitConverter.setMetric(_isMetric);

    ref.read(onboardingProvider.notifier).setMeasurements(
      heightCm: heightCm,
      weightKg: weightKg,
    );
    context.push('/onboarding/parent-height');
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
              _buildProgressBar(3, 13),
              const SizedBox(height: AppConstants.spacingXxl),
              Text("Your current measurements",
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: AppConstants.spacingSm),
              Text("We need your height and weight to calculate your BMI and growth potential.",
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppConstants.spacingLg),

              // Unit toggle
              Row(
                children: [
                  _unitButton('Metric (cm/kg)', true),
                  const SizedBox(width: 8),
                  _unitButton('Imperial (ft/lbs)', false),
                ],
              ),
              const SizedBox(height: AppConstants.spacingLg),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Height section
                      _sectionLabel('Height'),
                      const SizedBox(height: 8),
                      _isMetric
                          ? _buildMetricHeightPicker()
                          : _buildImperialHeightPicker(),
                      const SizedBox(height: AppConstants.spacingLg),

                      // Weight section
                      _sectionLabel('Weight'),
                      const SizedBox(height: 8),
                      _isMetric
                          ? _buildMetricWeightPicker()
                          : _buildImperialWeightPicker(),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : AppTheme.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? Colors.white : AppTheme.accent,
          fontWeight: FontWeight.w600, fontSize: 14,
        )),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label, style: GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary,
    ));
  }

  Widget _buildMetricHeightPicker() {
    final items = List.generate(81, (i) => '${140 + i} cm');
    return ScrollPicker(
      items: items,
      initialIndex: _selectedHeightCm - 140,
      onSelected: (i) => setState(() => _selectedHeightCm = 140 + i),
    );
  }

  Widget _buildImperialHeightPicker() {
    final feetItems = List.generate(4, (i) => '${4 + i} ft');
    final inchItems = List.generate(12, (i) => '$i in');
    return DualScrollPicker(
      leftItems: feetItems,
      rightItems: inchItems,
      initialLeftIndex: _selectedFeet - 4,
      initialRightIndex: _selectedInches,
      leftLabel: 'Feet',
      rightLabel: 'Inches',
      onLeftChanged: (i) => setState(() => _selectedFeet = 4 + i),
      onRightChanged: (i) => setState(() => _selectedInches = i),
    );
  }

  Widget _buildMetricWeightPicker() {
    final items = List.generate(111, (i) => '${40 + i} kg');
    return ScrollPicker(
      items: items,
      initialIndex: _selectedWeightKg - 40,
      onSelected: (i) => setState(() => _selectedWeightKg = 40 + i),
    );
  }

  Widget _buildImperialWeightPicker() {
    final items = List.generate(241, (i) => '${90 + i} lbs');
    return ScrollPicker(
      items: items,
      initialIndex: _selectedWeightLbs - 90,
      onSelected: (i) => setState(() => _selectedWeightLbs = 90 + i),
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
