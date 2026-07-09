import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/onboarding_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';

class GenderSelectionScreen extends ConsumerWidget {
  const GenderSelectionScreen({super.key});

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
              // Progress
              _buildProgressBar(1, 13),
              const SizedBox(height: AppConstants.spacingXxl),

              Text("What's your gender?",
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                "This helps us calculate your growth potential accurately.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: AppConstants.spacingXxl),

              // Gender cards — thumb zone
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _GenderCard(
                      emoji: '♂️',
                      title: 'Male',
                      subtitle: 'Growth typically continues until age 21',
                      color: const Color(0xFF42A5F5),
                      onTap: () {
                        ref.read(onboardingProvider.notifier).setGender('male');
                        context.push('/onboarding/birth-date');
                      },
                    ),
                    const SizedBox(height: AppConstants.spacingLg),
                    _GenderCard(
                      emoji: '♀️',
                      title: 'Female',
                      subtitle: 'Growth typically continues until age 18',
                      color: const Color(0xFFEC407A),
                      onTap: () {
                        ref.read(onboardingProvider.notifier).setGender('female');
                        context.push('/onboarding/birth-date');
                      },
                    ),
                  ],
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

class _GenderCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _GenderCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingXl),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: AppConstants.spacingLg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }
}
