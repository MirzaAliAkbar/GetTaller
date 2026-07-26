import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/constants.dart';

/// Blocks the whole app behind a full-screen "No Internet Connection"
/// message whenever both wifi and mobile data are down. Ads (interstitial,
/// rewarded) require network to load, so this closes the offline loophole
/// around every ad-gated flow — AI Coach queries, Repeat Workout, etc.
///
/// Debounces momentary drops (elevator, subway, wifi handoff) by a few
/// seconds before showing the blocking screen, and auto-recovers as soon as
/// connectivity returns — no manual retry required, though Retry is offered.
class ConnectivityGate extends StatefulWidget {
  final Widget child;
  const ConnectivityGate({super.key, required this.child});

  @override
  State<ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends State<ConnectivityGate> {
  static const _debounce = Duration(seconds: 3);

  bool _offline = false;
  bool _checking = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _evaluate();
    _subscription =
        Connectivity().onConnectivityChanged.listen((_) => _evaluate());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _evaluate() async {
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);

    _debounceTimer?.cancel();

    if (hasConnection) {
      if (mounted && _offline) setState(() => _offline = false);
      return;
    }

    // Debounce before showing the blocking screen so a momentary drop
    // doesn't slam the UI.
    _debounceTimer = Timer(_debounce, () {
      if (mounted) setState(() => _offline = true);
    });
  }

  Future<void> _retry() async {
    setState(() => _checking = true);
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (mounted) {
      setState(() {
        _checking = false;
        if (hasConnection) _offline = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_offline) _OfflineScreen(checking: _checking, onRetry: _retry),
      ],
    );
  }
}

class _OfflineScreen extends StatelessWidget {
  final bool checking;
  final VoidCallback onRetry;
  const _OfflineScreen({required this.checking, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.backgroundLight,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 44,
                  color: AppTheme.error,
                ),
              ),
              const SizedBox(height: AppConstants.spacingXl),
              Text(
                'No Internet Connection',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: AppConstants.textXxl,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              const Text(
                'GetTaller needs an active connection to work. '
                'Please check your Wi-Fi or mobile data and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppConstants.textSm,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSectionLg),
              SizedBox(
                width: double.infinity,
                height: AppConstants.minTouchTarget + 8,
                child: ElevatedButton.icon(
                  onPressed: checking ? null : onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                    ),
                  ),
                  icon: checking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(
                    checking ? 'Checking...' : 'Try Again',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: AppConstants.textMd,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
