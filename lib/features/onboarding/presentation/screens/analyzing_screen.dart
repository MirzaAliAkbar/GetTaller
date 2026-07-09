import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/ads/ad_service.dart';

class AnalyzingScreen extends ConsumerStatefulWidget {
  const AnalyzingScreen({super.key});

  @override
  ConsumerState<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends ConsumerState<AnalyzingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  final _messages = [
    "Analyzing bone age...",
    "Calculating genetic potential...",
    "Evaluating growth plate status...",
    "Optimizing your 90-day plan...",
    "Almost there...",
  ];
  int _msgIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotateMessages();
    
    // Pre-load interstitial ad for the high-value action
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adServiceProvider).loadInterstitialAd(
        adUnitId: AppConstants.interstitialAnalysisAdUnitId,
      );
    });

    _navigateAfter();
  }

  void _rotateMessages() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return false;
      setState(() => _msgIndex = (_msgIndex + 1) % _messages.length);
      return true;
    });
  }

  Future<void> _navigateAfter() async {
    await Future.delayed(const Duration(seconds: 8));
    if (!mounted) return;
    
    // Show action-triggered interstitial before showing result
    await ref.read(adServiceProvider).showInterstitialAd();

    if (!mounted) return;
    context.push('/onboarding/insight');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.primaryLight],
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingXl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Animated icon
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => Transform.scale(
                    scale: _pulse.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Rotating message
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    _messages[_msgIndex],
                    key: ValueKey(_msgIndex),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Generating your personalized height prediction',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 1),

                // Step indicator
                Text(
                  '7 / 13 • Analysis in progress',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
