import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';

class OnboardingInsightScreen extends StatelessWidget {
  const OnboardingInsightScreen({super.key});

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
              _PBar(8, 13),
              const SizedBox(height: AppConstants.spacingXxl),

              Text("Did you know?",
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: AppConstants.spacingXl),

              Expanded(
                child: ListView(
                  children: [
                    _InsightCard(
                      icon: '🧬',
                      title: 'Genetics & Height',
                      content:
                          'Genetics only determine about 60-80% of your height. '
                          'The rest is influenced by nutrition, sleep, exercise, and posture.',
                      color: AppTheme.calmPurple,
                    ),
                    const SizedBox(height: 12),
                    _InsightCard(
                      icon: '💤',
                      title: 'HGH & Sleep',
                      content:
                          'Growth hormone is released in pulses throughout the day, '
                          'with the highest levels during deep sleep between 10 PM and 2 AM.',
                      color: AppTheme.sleepIndigo,
                    ),
                    const SizedBox(height: 12),
                    _InsightCard(
                      icon: '🏃',
                      title: 'Exercise Benefits',
                      content:
                          'Exercise helps stimulate growth plates, improves posture, '
                          'and promotes HGH release - especially hanging, swimming, and yoga.',
                      color: AppTheme.energyOrange,
                    ),
                    const SizedBox(height: 12),
                    _InsightCard(
                      icon: '🥗',
                      title: 'Nutrition Matters',
                      content:
                          'Protein, calcium, vitamin D, zinc, and magnesium are '
                          'critical nutrients for optimal linear growth.',
                      color: AppTheme.accent,
                    ),
                    const SizedBox(height: 12),
                    _InsightCard(
                      icon: '🧍',
                      title: 'Posture Correction',
                      content:
                          'Strengthening your core and improving alignment can add '
                          '1-3 cm to your height beyond bone growth alone.',
                      color: AppTheme.info,
                    ),
                  ],
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.push('/onboarding/result-preview'),
                  child: const Text('See My Results'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String icon, title, content;
  final Color color;

  const _InsightCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(content,
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PBar extends StatelessWidget {
  final int c, t;
  const _PBar(this.c, this.t);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step $c of $t',
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
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
