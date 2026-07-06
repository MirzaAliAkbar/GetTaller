import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/services/user_data_service.dart';

/// AR Height Measurement — Blueprint §4.5
/// Includes a manual height input fallback since ARCore requires specific hardware.
class ARHeightMeasureScreen extends ConsumerStatefulWidget {
  const ARHeightMeasureScreen({super.key});

  @override
  ConsumerState<ARHeightMeasureScreen> createState() => _ARHeightMeasureScreenState();
}

class _ARHeightMeasureScreenState extends ConsumerState<ARHeightMeasureScreen> {
  final _heightController = TextEditingController();

  @override
  void dispose() {
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Log Your Height'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingXl),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Illustration
              Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.accent.withOpacity(0.08), AppTheme.accentLight.withOpacity(0.04)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.height_rounded,
                        size: 40,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Enter your height manually',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stand straight against a wall for\nthe most accurate measurement',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary.withOpacity(0.8), height: 1.4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacingXxl),

              // Height input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _heightController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'Your height',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Text(
                      'cm',
                      style: TextStyle(fontSize: 18, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacingMd),

              // Instructions
              _InstructionRow(
                icon: Icons.check_circle_outline_rounded,
                text: 'Remove shoes for accurate measurement',
              ),
              const SizedBox(height: 8),
              _InstructionRow(
                icon: Icons.check_circle_outline_rounded,
                text: 'Stand with heels against a wall',
              ),
              const SizedBox(height: 8),
              _InstructionRow(
                icon: Icons.check_circle_outline_rounded,
                text: 'Look straight ahead, not up or down',
              ),

              const Spacer(flex: 2),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _saveHeight,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save Measurement'),
                ),
              ),

              const SizedBox(height: AppConstants.spacingSection),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveHeight() async {
    final value = double.tryParse(_heightController.text);
    if (value == null || value < 100 || value > 250) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid height (100-250 cm)')),
      );
      return;
    }

    final service = ref.read(userDataServiceProvider);
    await service.addHeightMeasurement(value);
    await service.updateCurrentHeight(value);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ Height saved! Next measurement in 30 days.'),
        backgroundColor: AppTheme.accent,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) context.pop();
  }
}

class _InstructionRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InstructionRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Icon(icon, color: AppTheme.accent, size: 20),
        const SizedBox(width: 14),
        Text(text, style: const TextStyle(fontSize: 14)),
      ]),
    );
  }
}
