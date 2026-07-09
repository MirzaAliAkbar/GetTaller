import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';

class PrivacyShieldScreen extends StatelessWidget {
  const PrivacyShieldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingXl),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: AppTheme.success,
                  size: 56,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Your Data. Your Phone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'We physically cannot see your information.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              _buildPrivacyPoint(
                Icons.cloud_off_rounded,
                'No Cloud Storage',
                'Your measurements, logs, and profile stay 100% local on this device.',
              ),
              const SizedBox(height: 24),
              _buildPrivacyPoint(
                Icons.no_accounts_rounded,
                'No Account Required',
                'No email, no password, no tracking. Use GetTaller anonymously.',
              ),
              const SizedBox(height: 24),
              _buildPrivacyPoint(
                Icons.lock_outline_rounded,
                'Privacy First Monetization',
                'We use non-personalized ads to stay 100% free without selling data.',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.push('/onboarding/gender'),
                  child: const Text('I Understand & Agree'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyPoint(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.accent, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
