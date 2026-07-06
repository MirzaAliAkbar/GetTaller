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
              Text("What year were you born?",
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                "Just the year — we calculate your age from it.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppConstants.spacingXl),
              Expanded(
                child: Center(
                  child: _YearPickerCard(),
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

class _YearPickerCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_YearPickerCard> createState() => _YearPickerCardState();
}

class _YearPickerCardState extends ConsumerState<_YearPickerCard> {
  late final FixedExtentScrollController _scrollController;
  int _selectedIndex = 30; // Default ~1990

  static const int _startYear = 1960;
  static const int _endYear = 2020;

  List<int> get _years =>
      List.generate(_endYear - _startYear + 1, (i) => _startYear + i);

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final years = _years;
    if (years.isEmpty) return const Center(child: Text('No data'));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Year spinner
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(24),
          ),
          child: ListWheelScrollView.useDelegate(
            controller: _scrollController,
            itemExtent: 56,
            perspective: 0.003,
            diameterRatio: 1.5,
            onSelectedItemChanged: (index) {
              setState(() => _selectedIndex = index);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: years.length,
              builder: (context, index) {
                final year = years[index];
                final isSelected = index == _selectedIndex;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      '$year',
                      style: GoogleFonts.inter(
                        fontSize: isSelected ? 32 : 20,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected
                            ? AppTheme.accent
                            : AppTheme.textTertiary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: AppConstants.spacingXxl),

        // Continue button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              final selectedYear = years[_selectedIndex];
              // Use July 1 as the default birth date
              ref.read(onboardingProvider.notifier).setBirthDate(
                    DateTime(selectedYear, 7, 1),
                  );
              context.go('/onboarding/measurements');
            },
            child: const Text('Continue'),
          ),
        ),
      ],
    );
  }
}
