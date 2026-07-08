import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';

class GrowthWindowTimer extends StatelessWidget {
  final int ageYears;
  final int birthYear;
  final int birthMonth;

  const GrowthWindowTimer({
    super.key,
    required this.ageYears,
    required this.birthYear,
    required this.birthMonth,
  });

  @override
  Widget build(BuildContext context) {
    // Plates typically fuse by 19-21. We'll use 21 as the absolute limit.
    if (ageYears >= 21) return const SizedBox.shrink();

    final now = DateTime.now();
    // Closure date = Birth year + 21, at the end of their birth month.
    final closureDate = DateTime(birthYear + 21, birthMonth + 1, 0);
    
    final diff = closureDate.difference(now);
    if (diff.isNegative) return const SizedBox.shrink();

    final weeksLeft = (diff.inDays / 7).floor();

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingLg),
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D0A5E), Color(0xFF1A0636)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Colors.white70, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Critical Growth Window',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Time left until growth plates typically close',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$weeksLeft',
                style: const TextStyle(
                  color: AppTheme.energyOrange,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
              const Text(
                'WEEKS LEFT',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
