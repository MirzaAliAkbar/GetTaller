import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/utils/constants.dart';
import '../../core/services/subscription_service.dart';

/// Anchored Banner Ad widget — Blueprint §4.3
/// Thread-safe wrapper with lifecycle management.
/// Premium users see no banner — returns empty SizedBox.
class BannerAdWidget extends ConsumerStatefulWidget {
  final String? adUnitId;

  const BannerAdWidget({super.key, this.adUnitId});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    // Premium users never see ads.
    if (!SubscriptionService().isPremium) {
      _loadAd();
    }
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId ?? AppConstants.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _bannerAd = null);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use reactive provider — rebuilds when premium status changes.
    final premiumAsync = ref.watch(isPremiumProvider);
    final isPremium = premiumAsync.valueOrNull ?? false;

    // Premium users never see ads.
    if (isPremium) {
      return const SizedBox.shrink();
    }

    if (_bannerAd == null || !_isLoaded) {
      return const SizedBox(height: 50);
    }

    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.grey.shade50,
      child: Center(
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }
}
