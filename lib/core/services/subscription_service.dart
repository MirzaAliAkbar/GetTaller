import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// Manages Play Store subscriptions via in_app_purchase (Billing Library 9.x).
///
/// Provides a single source of truth for premium status across the app.
/// Free users see ads and have limited queries; premium users get no ads,
/// offline access, and 10 AI queries/day.
///
/// **Expiry handling:**
/// - `restorePurchases()` is called on every app foreground and on init.
/// - If the restore response contains no active purchase for our product,
///   premium is revoked.
/// - `PurchaseStatus.canceled` immediately revokes premium.
/// - `PurchaseStatus.purchased` / `PurchaseStatus.restored` grant premium.
class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService _instance = SubscriptionService._();
  factory SubscriptionService() => _instance;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  ProductDetails? _product;
  bool _isPremium = false;
  bool _isStoreAvailable = false;
  bool _isInitialized = false;

  /// Reactive premium status — widgets should listen to this for rebuilds.
  final StreamController<bool> _premiumController = StreamController<bool>.broadcast();
  Stream<bool> get premiumStream => _premiumController.stream;

  /// Whether the user currently has an active premium subscription.
  bool get isPremium => _isPremium;

  /// The monthly premium product (fetched from Play Store).
  ProductDetails? get product => _product;

  /// Whether the Play Store connection succeeded.
  bool get isStoreAvailable => _isStoreAvailable;

  /// Current price string, e.g. "\$3.99/month".
  String get priceString => _product?.price ?? '\$3.99/month';

  // ── Initialization ──

  /// Call once at app startup. Restores previous purchases and begins
  /// listening for new purchase events.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Restore cached premium status for instant UI (offline-safe).
    await _loadCachedPremiumStatus();

    // Connect to the store.
    _isStoreAvailable = await _iap.isAvailable();
    if (!_isStoreAvailable) {
      debugPrint('[Subscription] Store not available');
      return;
    }

    // Fetch the product details.
    await _loadProduct();

    // Restore any existing purchases — also checks for expiry.
    await restorePurchases();

    // Listen for real-time purchase events.
    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (e) => debugPrint('[Subscription] purchaseStream error: $e'),
    );
  }

  /// Dispose resources.
  void dispose() {
    _purchaseSub?.cancel();
  }

  // ── Product Loading ──

  Future<void> _loadProduct() async {
    try {
      final response = await _iap.queryProductDetails({
        AppConstants.premiumProductId,
      });
      if (response.productDetails.isNotEmpty) {
        _product = response.productDetails.first;
        debugPrint('[Subscription] Product loaded: ${_product!.title} — ${_product!.price}');
      } else {
        debugPrint('[Subscription] Product not found: ${AppConstants.premiumProductId}');
      }
    } catch (e) {
      debugPrint('[Subscription] Failed to load product: $e');
    }
  }

  // ── Purchase Flow ──

  /// Initiate a premium subscription purchase.
  /// Returns true if the purchase dialog was shown successfully.
  Future<bool> buyPremium() async {
    if (_product == null) {
      debugPrint('[Subscription] No product available');
      return false;
    }
    if (!_isStoreAvailable) {
      debugPrint('[Subscription] Store not available');
      return false;
    }

    try {
      final param = PurchaseParam(productDetails: _product!);
      final success = await _iap.buyNonConsumable(purchaseParam: param);
      return success;
    } catch (e) {
      debugPrint('[Subscription] Buy failed: $e');
      return false;
    }
  }

  // ── Restore & Expiry Verification ──

  Timer? _restoreTimeout;
  bool _restoreInProgress = false;
  bool _restoreReceivedValidPurchase = false;

  /// Restore previous purchases. Also used to verify subscription is still
  /// active — if no valid purchase is found, premium is revoked.
  /// Should be called on every app foreground and on startup.
  Future<void> restorePurchases() async {
    if (!_isStoreAvailable) return;

    // Don't stack multiple restores.
    if (_restoreInProgress) return;
    _restoreInProgress = true;
    _restoreReceivedValidPurchase = false;

    try {
      _iap.restorePurchases();
    } catch (e) {
      debugPrint('[Subscription] Restore failed: $e');
      _restoreInProgress = false;
      return;
    }

    // After 5 seconds, check if we received any valid purchase.
    // If the batch was empty (expired subscription), the stream may not fire.
    _restoreTimeout?.cancel();
    _restoreTimeout = Timer(const Duration(seconds: 5), () {
      _restoreInProgress = false;
      if (!_restoreReceivedValidPurchase && _isPremium) {
        debugPrint('[Subscription] No active subscription found after restore — revoking premium');
        _setPremium(false);
        _logSubscriptionEvent('expire');
      }
    });
  }

  /// Public restore — called from the UI (Restore Purchase button).
  Future<void> restorePurchaseFromUI() async {
    if (!_isStoreAvailable) return;
    await restorePurchases();
  }

  // ── Purchase Handling ──

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    // Cancel the expiry timeout — we got purchases back.
    _restoreTimeout?.cancel();
    _restoreReceivedValidPurchase = false;

    for (final purchase in purchases) {
      _handlePurchase(purchase);
    }

    // If we got a valid purchase, cancel the timeout and mark restore complete.
    if (_restoreReceivedValidPurchase) {
      _restoreInProgress = false;
    } else {
      // No valid purchase in this batch — restart timeout to check for expiry.
      _restoreTimeout?.cancel();
      _restoreTimeout = Timer(const Duration(seconds: 3), () {
        _restoreInProgress = false;
        if (!_restoreReceivedValidPurchase && _isPremium) {
          debugPrint('[Subscription] No active subscription found — revoking premium');
          _setPremium(false);
          _logSubscriptionEvent('expire');
        }
      });
    }
  }

  void _handlePurchase(PurchaseDetails purchase) {
    if (purchase.productID != AppConstants.premiumProductId) return;

    switch (purchase.status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // Valid subscription — grant or maintain premium.
        _setPremium(true);
        _restoreReceivedValidPurchase = true;
        _logSubscriptionEvent('purchase');
        break;

      case PurchaseStatus.canceled:
        // User explicitly canceled — revoke premium immediately.
        debugPrint('[Subscription] Subscription canceled');
        _setPremium(false);
        _logSubscriptionEvent('cancel');
        break;

      case PurchaseStatus.error:
        debugPrint('[Subscription] Purchase error: ${purchase.error}');
        // Don't change premium status on error — could be network issue.
        break;

      case PurchaseStatus.pending:
        // Payment is processing — don't change status yet.
        debugPrint('[Subscription] Purchase pending');
        break;
    }

    // Complete pending purchases to acknowledge receipt.
    if (purchase.pendingCompletePurchase) {
      _iap.completePurchase(purchase);
    }
  }

  // ── Log subscription event to affiliate backend ──

  Future<void> _logSubscriptionEvent(String eventType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final installId = prefs.getString(AppConstants.prefInstallId);
      final referralCode = prefs.getString(AppConstants.prefReferralCode);

      if (installId == null) return;

      final response = await http.post(
        Uri.parse('${AppConstants.affiliateBackendUrl}/v1/events/subscription'),
        headers: {'Content-Type': 'application/json'},
        body: {
          'userId': installId,
          'eventType': eventType,
          'productId': AppConstants.premiumProductId,
          'amountCents': 399,
          'currency': 'USD',
          'platform': 'android',
          'referralCode': referralCode,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('[Subscription] Logged $eventType event to affiliate backend');
      } else {
        debugPrint('[Subscription] Failed to log event: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[Subscription] Error logging event: $e');
    }
  }

  // ── Premium Status Persistence ──

  Future<void> _setPremium(bool value) async {
    if (_isPremium == value) return; // No change, skip
    _isPremium = value;
    _premiumController.add(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefIsPremium, value);
    debugPrint('[Subscription] Premium status updated: $value');
  }

  Future<void> _loadCachedPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(AppConstants.prefIsPremium) ?? false;
    _premiumController.add(_isPremium);
  }
}

// ── Riverpod Providers ──

/// Singleton provider for the subscription service.
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final service = SubscriptionService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Reactive premium status — rebuilds widgets when premium changes.
final isPremiumProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return service.premiumStream;
});

/// Synchronous premium check — reads the cached value.
/// Use this for instant UI decisions (ad skip, query limits).
final isPremiumSyncProvider = Provider<bool>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return service.isPremium;
});
