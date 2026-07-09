import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/onboarding_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';

class SportsSelectionScreen extends ConsumerWidget {
  const SportsSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.pop())),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingXl),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Step 5 of 13', style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: 5/13, backgroundColor: AppTheme.accent.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation(AppTheme.accent), minHeight: 6),
            ),
            const SizedBox(height: AppConstants.spacingXxl),
            Text("What's your lifestyle?", style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: AppConstants.spacingSm),
            Text("Choose the option that best describes your daily activity level.",
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppConstants.spacingXxl),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActivityCard(
                    icon: Icons.weekend_rounded,
                    emoji: '🛋️',
                    title: 'Sedentary',
                    subtitle: 'Little to no exercise.\nMostly sitting throughout the day.',
                    value: 'sedentary',
                    color: AppTheme.textTertiary,
                    ref: ref,
                  ),
                  const SizedBox(height: 16),
                  _ActivityCard(
                    icon: Icons.directions_walk_rounded,
                    emoji: '🚶',
                    title: 'Moderately Active',
                    subtitle: 'Exercise 3–5 days per week.\nActive daily routine.',
                    value: 'moderate',
                    color: AppTheme.info,
                    ref: ref,
                  ),
                  const SizedBox(height: 16),
                  _ActivityCard(
                    icon: Icons.directions_run_rounded,
                    emoji: '🏃',
                    title: 'Active',
                    subtitle: 'Daily exercise or sports.\nVery active lifestyle.',
                    value: 'active',
                    color: AppTheme.accent,
                    ref: ref,
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final String emoji, title, subtitle, value;
  final Color color;
  final WidgetRef ref;

  const _ActivityCard({
    required this.icon,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ref.read(onboardingProvider.notifier).setActivityLevel(value);
        context.push('/onboarding/sleep');
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.2), width: 2),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ])),
          Icon(Icons.chevron_right_rounded, color: color),
        ]),
      ),
    );
  }
}
