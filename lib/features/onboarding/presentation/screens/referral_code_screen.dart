import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/services/attribution_service.dart';
import '../providers/onboarding_provider.dart';

/// Optional referral code entry screen.
///
/// Shown after Privacy Shield. User can skip with zero friction.
/// Live-validates the code against the backend (debounced 500ms).
class ReferralCodeScreen extends ConsumerStatefulWidget {
  const ReferralCodeScreen({super.key});

  @override
  ConsumerState<ReferralCodeScreen> createState() => _ReferralCodeScreenState();
}

class _ReferralCodeScreenState extends ConsumerState<ReferralCodeScreen> {
  final _codeController = TextEditingController();
  bool _isValidating = false;
  bool _isValid = false;
  String? _validationMessage;
  Timer? _debounce;

  @override
  void dispose() {
    _codeController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onCodeChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _isValidating = false;
        _isValid = false;
        _validationMessage = null;
      });
      return;
    }

    setState(() => _isValidating = true);

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final result = await AttributionService().validateCode(value.trim());
      if (!mounted) return;
      setState(() {
        _isValidating = false;
        if (result != null && result.valid) {
          _isValid = true;
          _validationMessage = 'Valid code! You\'re supporting an influencer.';
        } else {
          _isValid = false;
          _validationMessage = 'Code not recognized. You can skip this.';
        }
      });
    });
  }

  void _onContinue() {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isNotEmpty && _isValid) {
      ref.read(onboardingProvider.notifier).setReferralCode(code);
    }
    context.push('/onboarding/gender');
  }

  void _onSkip() {
    context.push('/onboarding/gender');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.discount_rounded,
                  color: AppTheme.accent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              // Title
              const Text(
                'Got a Referral Code?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter it below to support your influencer. '
                '100% optional — skip if you don\'t have one.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Code input field
              TextField(
                controller: _codeController,
                onChanged: _onCodeChanged,
                autocorrect: false,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'e.g. SARAH20',
                  hintStyle: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.5),
                    letterSpacing: 1,
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    borderSide: BorderSide(
                      color: _isValid
                          ? AppTheme.success
                          : AppTheme.textTertiary,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    borderSide: BorderSide(
                      color: _isValid ? AppTheme.success : AppTheme.accent,
                      width: 2,
                    ),
                  ),
                  suffixIcon: _isValidating
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _codeController.text.isNotEmpty
                          ? Icon(
                              _isValid
                                  ? Icons.check_circle_rounded
                                  : Icons.info_outline_rounded,
                              color: _isValid
                                  ? AppTheme.success
                                  : AppTheme.textSecondary,
                            )
                          : null,
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),

              // Validation message
              if (_validationMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _validationMessage!,
                    style: TextStyle(
                      fontSize: 13,
                      color: _isValid ? AppTheme.success : AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const Spacer(),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onContinue,
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 12),

              // Skip link
              Center(
                child: GestureDetector(
                  onTap: _onSkip,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
