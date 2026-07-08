import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';

class GapVisualization extends StatelessWidget {
  final Map<String, double> gaps;
  final double potentialGain;

  const GapVisualization({
    super.key,
    required this.gaps,
    required this.potentialGain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Height Potential Gaps',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.energyOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(potentialGain * 10).toStringAsFixed(0)}mm to unlock',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.energyOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGapBar('Sleep Optimization', gaps['sleep'] ?? 0, 10, AppTheme.sleepIndigo),
          const SizedBox(height: 12),
          _buildGapBar('Nutrition & BMI', gaps['nutrition'] ?? 0, 15, AppTheme.success),
          const SizedBox(height: 12),
          _buildGapBar('Posture Restoration', gaps['posture'] ?? 0, 5, AppTheme.accent),
          const SizedBox(height: 16),
          const Text(
            'Each bar represents potential height "locked" due to lifestyle factors. '
            'Follow your daily plan to unlock these millimeters.',
            style: TextStyle(fontSize: 11, color: AppTheme.textTertiary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildGapBar(String label, double value, double maxVal, Color color) {
    final progress = 1.0 - (value / maxVal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text(
              value > 0 ? '-${value.toStringAsFixed(1)}mm' : 'Unlocked!',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: value > 0 ? AppTheme.textSecondary : AppTheme.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
