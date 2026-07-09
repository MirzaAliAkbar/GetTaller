import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/onboarding_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';

class BirthDateScreen extends ConsumerWidget {
  const BirthDateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              _buildProgressBar(2, 13),
              const SizedBox(height: AppConstants.spacingXxl),
              Text("When were you born?",
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                "We use your birth year and month to track your precise growth window.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppConstants.spacingXl),
              const Expanded(
                child: Center(
                  child: _BirthDatePicker(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(int current, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step $current of $total',
            style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
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

class _BirthDatePicker extends ConsumerStatefulWidget {
  const _BirthDatePicker();

  @override
  ConsumerState<_BirthDatePicker> createState() => _BirthDatePickerState();
}

class _BirthDatePickerState extends ConsumerState<_BirthDatePicker> {
  late final FixedExtentScrollController _yearController;
  late final FixedExtentScrollController _monthController;
  
  int _selectedYearIndex = 45; // Default ~2005
  int _selectedMonthIndex = 6; // July

  static const int _startYear = 1960;
  final int _endYear = DateTime.now().year;

  List<int> get _years =>
      List.generate(_endYear - _startYear + 1, (i) => _startYear + i);
      
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _yearController = FixedExtentScrollController(initialItem: _selectedYearIndex);
    _monthController = FixedExtentScrollController(initialItem: _selectedMonthIndex);
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final years = _years;
    if (years.isEmpty) return const Center(child: Text('No data'));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // Month spinner
            Expanded(
              flex: 3,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                ),
                child: ListWheelScrollView.useDelegate(
                  controller: _monthController,
                  itemExtent: 56,
                  onSelectedItemChanged: (index) => setState(() => _selectedMonthIndex = index),
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: _months.length,
                    builder: (context, index) {
                      final month = _months[index];
                      final isSelected = index == _selectedMonthIndex;
                      return Center(
                        child: Text(
                          month,
                          style: GoogleFonts.inter(
                            fontSize: isSelected ? 20 : 16,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                            color: isSelected ? AppTheme.accent : AppTheme.textTertiary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            
            // Year spinner
            Expanded(
              flex: 2,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard.withOpacity(0.5),
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
                ),
                child: ListWheelScrollView.useDelegate(
                  controller: _yearController,
                  itemExtent: 56,
                  onSelectedItemChanged: (index) => setState(() => _selectedYearIndex = index),
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: years.length,
                    builder: (context, index) {
                      final year = years[index];
                      final isSelected = index == _selectedYearIndex;
                      return Center(
                        child: Text(
                          '$year',
                          style: GoogleFonts.inter(
                            fontSize: isSelected ? 24 : 18,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                            color: isSelected ? AppTheme.accent : AppTheme.textTertiary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppConstants.spacingXxl),

        // Continue button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              final selectedYear = years[_selectedYearIndex];
              final selectedMonth = _selectedMonthIndex + 1;
              
              ref.read(onboardingProvider.notifier).setBirthDate(
                    DateTime(selectedYear, selectedMonth, 1),
                  );
              context.push('/onboarding/measurements');
            },
            child: const Text('Continue'),
          ),
        ),
      ],
    );
  }
}
