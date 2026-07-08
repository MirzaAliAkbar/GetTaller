import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants.dart';

/// Ad lifecycle state tracked via Riverpod
enum AdLoadState { initial, loading, loaded, failed }

/// AdMob integration — Blueprint §3.3
/// Wraps Banner, Interstitial, Rewarded, and Native ads with lifecycle management.
class AdService {
  // ── Singleton ──
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  // ── Interstitial ──
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  int _interstitialRetries = 0;
  static const int _maxRetries = 3;

  // ── Rewarded ──
  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;
  Completer<bool>? _rewardedLoadCompleter;

  // ── Banner ──
  BannerAd? _bannerAd;
  bool _isBannerLoading = false;

  // ── Native ──
  NativeAd? _nativeAd;
  bool _isNativeLoading = false;

  // ── Callbacks ──
  void Function()? onInterstitialLoaded;
  void Function()? onInterstitialFailed;
  void Function()? onRewardEarned;
  void Function()? onRewardedFailed;
  void Function(double cpm)? onNativeAdImpression;

  // ── Initialization ──
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // ══════════════════════════════════════════════════════════════
  // INTERSTITIAL ADS — Blueprint §3.3: triggers after onboarding
  // ══════════════════════════════════════════════════════════════

  Future<void> loadInterstitialAd() async {
    if (_interstitialAd != null || _isInterstitialLoading) return;
    if (_interstitialRetries >= _maxRetries) return;

    _isInterstitialLoading = true;

    await InterstitialAd.load(
      adUnitId: AppConstants.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _interstitialRetries = 0;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _interstitialAd = null;
              // Pre-load next interstitial
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _interstitialAd = null;
              _isInterstitialLoading = false;
              onInterstitialFailed?.call();
            },
          );
          onInterstitialLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdMob interstitial error: code=${error.code} msg=${error.message}');
          _interstitialAd = null;
          _isInterstitialLoading = false;
          _interstitialRetries++;
          onInterstitialFailed?.call();
        },
      ),
    );
  }

  Future<bool> showInterstitialAd() async {
    if (_interstitialAd == null) return false;
    _interstitialAd!.show();
    return true;
  }

  // ══════════════════════════════════════════════════════════════
  // REWARDED ADS — Blueprint §3.3: gates AI coach queries
  // ══════════════════════════════════════════════════════════════

  Future<bool> loadRewardedAd() async {
    if (_rewardedAd != null) return true;
    if (_isRewardedLoading && _rewardedLoadCompleter != null) {
      return _rewardedLoadCompleter!.future;
    }

    _isRewardedLoading = true;
    _rewardedLoadCompleter = Completer<bool>();

    RewardedAd.load(
      adUnitId: AppConstants.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _rewardedAd = null;
              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Rewarded ad failed to show: ${error.message}');
              _rewardedAd = null;
              _isRewardedLoading = false;
              onRewardedFailed?.call();
            },
          );
          if (_rewardedLoadCompleter != null && !_rewardedLoadCompleter!.isCompleted) {
            _rewardedLoadCompleter!.complete(true);
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdMob rewarded error: code=${error.code} msg=${error.message}');
          debugPrint('If "No fill" — add your device hash to AdMob console > Settings > Test devices');
          debugPrint('Find hash: run app → check logcat for "Use new consent" line with device ID');
          _rewardedAd = null;
          _isRewardedLoading = false;
          if (_rewardedLoadCompleter != null && !_rewardedLoadCompleter!.isCompleted) {
            _rewardedLoadCompleter!.complete(false);
          }
        },
      ),
    );

    return _rewardedLoadCompleter!.future;
  }

  Future<bool> showRewardedAd() async {
    if (_rewardedAd == null) return false;

    final completer = Completer<bool>();
    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onRewardEarned?.call();
        if (!completer.isCompleted) completer.complete(true);
      },
    );
    
    // Safety timeout or fallback if callback doesn't fire as expected
    return completer.future.timeout(const Duration(seconds: 60), onTimeout: () => true);
  }

  // ══════════════════════════════════════════════════════════════
  // BANNER ADS — Blueprint §4.3: anchored at Daily Plan bottom
  // ══════════════════════════════════════════════════════════════

  BannerAd? createBannerAd() {
    if (_isBannerLoading) return null;

    _isBannerLoading = true;
    final ad = BannerAd(
      adUnitId: AppConstants.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _bannerAd = ad as BannerAd;
          _isBannerLoading = false;
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdMob banner error: code=${error.code} msg=${error.message}');
          _bannerAd = null;
          _isBannerLoading = false;
          ad.dispose();
        },
        onAdOpened: (ad) {},
        onAdClosed: (ad) {},
      ),
    )..load();
    return ad;
  }

  // ══════════════════════════════════════════════════════════════
  // NATIVE ADS — Blueprint §4.4: blended into AI Coach chat
  // ══════════════════════════════════════════════════════════════

  NativeAd? createNativeAd() {
    if (_isNativeLoading) return null;

    _isNativeLoading = true;
    final ad = NativeAd(
      adUnitId: AppConstants.nativeAdUnitId,
      request: const AdRequest(),
      nativeAdOptions: NativeAdOptions(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _nativeAd = ad as NativeAd;
          _isNativeLoading = false;
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdMob native error: code=${error.code} msg=${error.message}');
          _nativeAd = null;
          _isNativeLoading = false;
          ad.dispose();
        },
        onAdImpression: (ad) {
          onNativeAdImpression?.call(0.0);
        },
      ),
    )..load();
    return ad;
  }

  // ── Cleanup ──
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _bannerAd?.dispose();
    _nativeAd?.dispose();
  }
}

// ── Riverpod Providers ──

final adServiceProvider = Provider<AdService>((ref) {
  final service = AdService();
  ref.onDispose(() => service.dispose());
  return service;
});

final interstitialAdStateProvider = StateNotifierProvider<InterstitialAdNotifier, AdLoadState>(
  (ref) => InterstitialAdNotifier(ref),
);

class InterstitialAdNotifier extends StateNotifier<AdLoadState> {
  final Ref _ref;

  InterstitialAdNotifier(this._ref) : super(AdLoadState.initial);

  Future<void> load() async {
    state = AdLoadState.loading;
    final service = _ref.read(adServiceProvider);
    service.onInterstitialLoaded = () {
      if (mounted) state = AdLoadState.loaded;
    };
    service.onInterstitialFailed = () {
      if (mounted) state = AdLoadState.failed;
    };
    await service.loadInterstitialAd();
  }

  Future<bool> show() async {
    final service = _ref.read(adServiceProvider);
    final shown = await service.showInterstitialAd();
    if (mounted) state = AdLoadState.initial;
    return shown;
  }
}

final rewardedAdStateProvider = StateNotifierProvider<RewardedAdNotifier, AdLoadState>(
  (ref) => RewardedAdNotifier(ref),
);

class RewardedAdNotifier extends StateNotifier<AdLoadState> {
  final Ref _ref;
  bool _rewardGranted = false;

  RewardedAdNotifier(this._ref) : super(AdLoadState.initial);

  bool get rewardGranted => _rewardGranted;

  Future<bool> load() async {
    state = AdLoadState.loading;
    _rewardGranted = false;
    final service = _ref.read(adServiceProvider);
    service.onRewardEarned = () {
      _rewardGranted = true;
    };
    service.onRewardedFailed = () {
      if (mounted) state = AdLoadState.failed;
    };
    final loaded = await service.loadRewardedAd();
    if (mounted) {
      state = loaded ? AdLoadState.loaded : AdLoadState.failed;
    }
    return loaded;
  }

  Future<bool> show() async {
    final service = _ref.read(adServiceProvider);
    final shown = await service.showRewardedAd();
    if (mounted) state = AdLoadState.initial;
    return shown;
  }
}
