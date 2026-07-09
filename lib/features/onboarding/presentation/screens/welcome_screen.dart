import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/services/analytics_service.dart';
import '../providers/onboarding_provider.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _nameController = TextEditingController();
  bool _nameEntered = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logOnboardingStep(1, 'welcome');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      ref.read(onboardingProvider.notifier).setName(name);
      // Save for notification service and dashboard to read
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_display_name', name);
    }
    if (!mounted) return;
    
    // Show Medical Disclaimer before proceeding
    final proceed = await _showDisclaimer(context);
    if (proceed != true) return;
    
    if (!mounted) return;
    context.push('/onboarding/privacy');
  }

  Future<bool?> _showDisclaimer(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Medical Disclaimer'),
        content: const SingleChildScrollView(
          child: Text(
            'GetTaller is for informational and educational purposes only. '
            'It is not a medical device and does not diagnose, treat, cure, or prevent any disease.\n\n'
            'Height growth is influenced by genetics, nutrition, sleep, and exercise. '
            'Results vary from person to person. The predictions and suggestions provided '
            'are estimates based on scientific averages and should not be taken as guarantees.\n\n'
            'Always consult with a qualified healthcare provider before starting any '
            'nutrition, exercise, or sleep program, especially for growing children and teenagers.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('I Understand & Agree'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppConstants.spacingXxl),

              // Icon
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.accent, AppTheme.accentLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // Headline
              Text(
                "Discover Your\nHeight Potential",
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: AppConstants.spacingLg),

              // Body
              Text(
                "Unlock your growth potential with a personalized 90-day plan. "
                "GetTaller combines genetics, nutrition, exercise science, "
                "and sleep optimization to help you stand taller.",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: AppConstants.spacingXxl),

              // Name input
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 18, color: AppTheme.accentDark),
                        const SizedBox(width: 8),
                        Text(
                          "What should we call you?",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (v) => setState(() => _nameEntered = v.trim().isNotEmpty),
                      decoration: InputDecoration(
                        hintText: "Your name",
                        hintStyle: TextStyle(color: AppTheme.textTertiary.withOpacity(0.5)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // Trust indicators
              Row(
                children: [
                  _trustChip('🔬 Science-Based'),
                  const SizedBox(width: 8),
                  _trustChip('📊 Personalized'),
                  const SizedBox(width: 8),
                  _trustChip('✅ Free'),
                ],
              ),

              const SizedBox(height: AppConstants.spacingXxl),

              // CTA button — thumb zone placement
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _onContinue,
                  child: Text(_nameEntered ? "Let's Go, ${_nameController.text.trim()}! →" : "Let's Begin"),
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),

              // Skip text
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/main'),
                  child: Text(
                    'Skip assessment (use basic plan)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // Privacy/trust footer
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingLg),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _privacyBadge(Icons.monetization_on_rounded, '100% Free'),
                    const SizedBox(width: 8),
                    _privacyBadge(Icons.lock_rounded, 'Privacy Protected'),
                    const SizedBox(width: 8),
                    _privacyBadge(Icons.person_off_rounded, 'No Account'),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacingSection),
            ],
          ),
        ),
      ),
    );
  }

  Widget _privacyBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.accent),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _trustChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppTheme.accentDark,
        ),
      ),
    );
  }
}
