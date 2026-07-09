import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/onboarding_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';

class AnalysisDepthScreen extends ConsumerWidget {
  const AnalysisDepthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.pop())),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingXl),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _PBar(7, 13), const SizedBox(height: AppConstants.spacingXxl),
            Text("Analysis depth", style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: AppConstants.spacingSm),
            Text("Choose how detailed you want your growth analysis to be.",
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppConstants.spacingXxl),
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              _DepthCard(
                icon: Icons.speed_rounded, title: 'Fast', subtitle: 'Basic prediction\nTakes 5 seconds',
                value: 'fast', color: AppTheme.info, ref: ref,
              ),
              const SizedBox(height: 16),
              _DepthCard(
                icon: Icons.auto_awesome_rounded, title: 'Accurate', subtitle: 'Full analysis with BMI, sleep & activity adjustments\nTakes 15 seconds',
                value: 'accurate', color: AppTheme.accent, ref: ref,
              ),
            ])),
          ]),
        ),
      ),
    );
  }
}

class _DepthCard extends StatelessWidget {
  final IconData icon; final String title, subtitle, value; final Color color; final WidgetRef ref;
  const _DepthCard({required this.icon, required this.title, required this.subtitle, required this.value, required this.color, required this.ref});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { ref.read(onboardingProvider.notifier).setAnalysisDepth(value); context.push('/onboarding/analyzing'); },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.2), width: 2),
        ),
        child: Row(children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(width: 20),
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

class _PBar extends StatelessWidget {
  final int c, t;
  const _PBar(this.c, this.t);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Step $c of $t', style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
    const SizedBox(height: 8),
    ClipRRect(borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(value: c / t, backgroundColor: AppTheme.accent.withOpacity(0.1),
          valueColor: const AlwaysStoppedAnimation(AppTheme.accent), minHeight: 6),
    ),
  ]);
}
