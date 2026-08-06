import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../core/theme/app_theme.dart';

/// Premium features page — shows benefits, price, and subscribe/restore buttons.
///
/// Design principles (Mobile App UI/UX):
/// - 60/30/10 color: 60% neutral (white bg), 30% primary (gradient accents),
///   10% accent (gold sparkle for premium feel).
/// - 8pt grid: all spacing divisible by 8.
/// - Thumb zone: CTA button at bottom 1/3 of screen.
/// - Peak-End Rule: beautiful gradient header, strong CTA.
/// - Health/Wellness: bright, approachable colors, friendly micro-interactions.
/// - Emotional feedback: celebration on successful subscription.
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen>
    with TickerProviderStateMixin {
  late AnimationController _sparkleController;
  late AnimationController _scaleController;
  bool _isSubscribing = false;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(subscriptionServiceProvider);
    final isPremium = subscription.isPremium;
    final price = subscription.priceString;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header with gradient + sparkles ──
            _buildHeader(context),

            // ── Benefits list ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // Benefit cards with health/fitness focus
                    _buildBenefitCard(
                      icon: Icons.trending_up_rounded,
                      title: 'Unlock Full Potential',
                      description: 'Get personalized insights and track your height growth progress with precision analytics.',
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: 16),
                    _buildBenefitCard(
                      icon: Icons.block_rounded,
                      title: 'No Ads, No Interruptions',
                      description: 'Focus on your growth journey without distractions. Clean, distraction-free experience.',
                      color: AppTheme.accent,
                    ),
                    const SizedBox(height: 16),
                    _buildBenefitCard(
                      icon: Icons.chat_rounded,
                      title: '5x More AI Coaching',
                      description: 'Get 10 free AI coach queries daily instead of 2. Ask more, learn more, grow more.',
                      color: AppTheme.success,
                    ),
                    const SizedBox(height: 16),
                    _buildBenefitCard(
                      icon: Icons.offline_bolt_rounded,
                      title: 'Works Offline',
                      description: 'Access your workouts and daily plan anywhere, even without internet connection.',
                      color: AppTheme.warning,
                    ),
                    const SizedBox(height: 24),

                    // ── Price badge with subtle glow ──
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.25),
                            blurRadius: 16,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '$price · Cancel anytime',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join 10,000+ users growing taller',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── CTA buttons (thumb zone) ──
            _buildCTASection(context, subscription, isPremium),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.primaryDark,
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Close button
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 28),
            ),
          ),
          const SizedBox(height: 8),
          // Premium icon with sparkle animation
          AnimatedBuilder(
            animation: _sparkleController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3 * sin(_sparkleController.value * pi * 2) * 0.5 + 0.5),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 52),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Go Premium',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock the full GetTaller experience',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection(
    BuildContext context,
    SubscriptionService subscription,
    bool isPremium,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPremium) ...[
            // Already premium - celebratory state
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.success, AppTheme.success.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.success.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Premium Active',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Subscribe button with animation
            ScaleTransition(
              scale: _scaleController,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubscribing ? null : () => _handleSubscribe(subscription),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.primary.withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    shadowColor: AppTheme.primary.withOpacity(0.4),
                  ),
                  child: _isSubscribing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          'Subscribe — ${subscription.priceString}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Restore button
            TextButton(
              onPressed: () => _handleRestore(subscription),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Restore Purchase',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleSubscribe(SubscriptionService subscription) async {
    setState(() => _isSubscribing = true);
    _scaleController.forward(from: 0.95);

    try {
      final success = await subscription.buyPremium();
      if (mounted) {
        setState(() => _isSubscribing = false);
        if (success) {
          _showCelebration();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isSubscribing = false);
    }
  }

  Future<void> _handleRestore(SubscriptionService subscription) async {
    await subscription.restorePurchases();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            subscription.isPremium
                ? 'Welcome back! Premium restored.'
                : 'No active subscription found.',
          ),
          backgroundColor: subscription.isPremium
              ? AppTheme.success
              : AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showCelebration() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🎉 '),
            Text(
              'Welcome to Premium!',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
