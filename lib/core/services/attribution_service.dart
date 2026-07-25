import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../utils/constants.dart';
import 'remote_config_service.dart';

/// Result of validating a referral code with the backend.
class CodeValidation {
  final bool valid;
  final int? sharePercent;
  final String? influencerId;

  CodeValidation({
    required this.valid,
    this.sharePercent,
    this.influencerId,
  });
}

/// Batched ad revenue event waiting to be flushed.
class _AdEvent {
  final String installId;
  final String code;
  final String adFormat;
  final int valueMicros;
  final String currency;
  final int precision;

  _AdEvent({
    required this.installId,
    required this.code,
    required this.adFormat,
    required this.valueMicros,
    required this.currency,
    required this.precision,
  });

  Map<String, dynamic> toJson() => {
    'installId': installId,
    'code': code,
    'adFormat': adFormat,
    'valueMicros': valueMicros,
    'currency': currency,
    'precision': precision,
  };
}

/// Attribution service for the affiliate referral program.
///
/// Singleton — mirrors [AiService] pattern. All network calls are
/// fire-and-forget with silent try/catch. Only fires requests for users
/// who entered a referral code (privacy guarantee).
class AttributionService {
  static final AttributionService _instance = AttributionService._();
  factory AttributionService() => _instance;
  AttributionService._();

  String? _installId;
  String? _referralCode;
  String? _baseUrl;
  bool _enabled = true;
  bool _initialized = false;

  // ── Ad event batching ──
  final List<_AdEvent> _adEventBuffer = [];
  Timer? _flushTimer;

  /// Initialize the service. Call once at startup from main.dart.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Mint or load install ID
      _installId = prefs.getString(AppConstants.prefInstallId);
      if (_installId == null) {
        _installId = const Uuid().v4();
        await prefs.setString(AppConstants.prefInstallId, _installId!);
      }

      // Load cached referral code
      _referralCode = prefs.getString(AppConstants.prefReferralCode);

      // Remote Config overrides
      try {
        final rc = RemoteConfigService();
        _baseUrl = rc.getAttributionBaseUrl();
        _enabled = rc.isAttributionEnabled();
      } catch (_) {
        _baseUrl = AppConstants.attributionBaseUrl;
      }
    } catch (e) {
      debugPrint('AttributionService init error: $e');
    }

    _initialized = true;
  }

  /// Whether a referral code is cached (user attributed).
  bool get hasReferralCode => _referralCode != null && _referralCode!.isNotEmpty;

  /// The cached referral code, if any.
  String? get referralCode => _referralCode;

  /// Set (cache) a referral code locally. Called when user enters one
  /// during onboarding.
  Future<void> setReferralCode(String code) async {
    _referralCode = code.toUpperCase();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefReferralCode, _referralCode!);
    } catch (_) {}
  }

  /// Clear the cached referral code.
  Future<void> clearReferralCode() async {
    _referralCode = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.prefReferralCode);
    } catch (_) {}
  }

  // ── API Base ──

  String get _apiBase => _baseUrl ?? AppConstants.attributionBaseUrl;

  // ── Guard: skip if attribution disabled or no code ──
  bool get _canSend => _enabled && _installId != null;

  // ── HTTP helpers ──

  Future<Map<String, dynamic>?> _post(String path, Map<String, dynamic> body) async {
    if (!_canSend) return null;
    try {
      final uri = Uri.parse('$_apiBase$path');
      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ── Public API ──

  /// Validate a referral code against the backend.
  /// Returns null on error, [CodeValidation] on success.
  Future<CodeValidation?> validateCode(String code) async {
    if (!_enabled) return null;
    try {
      final uri = Uri.parse('$_apiBase/v1/validate').replace(queryParameters: {
        'code': code.toUpperCase(),
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['valid'] == true) {
          return CodeValidation(
            valid: true,
            sharePercent: data['sharePercent'] as int?,
            influencerId: data['influencerId'] as String?,
          );
        }
        return CodeValidation(valid: false);
      }
    } catch (_) {}
    return null;
  }

  /// Log a new signup (attribution event). Called after onboarding completes.
  Future<void> logSignup({
    required String code,
    String? country,
    String? platform,
    String? appVersion,
  }) async {
    await _post('/v1/events/signup', {
      'installId': _installId,
      'code': code.toUpperCase(),
      'country': country,
      'platform': platform,
      'appVersion': appVersion,
    });
  }

  /// Log an ad revenue event. Accumulates in batch buffer and flushes
  /// every [attributionFlushIntervalMs] ms or [attributionBatchSize] events.
  Future<void> logAdRevenue({
    required int valueMicros,
    required String adFormat,
    required String code,
    String currency = 'USD',
    int precision = 0,
  }) async {
    if (!_canSend || _referralCode == null) return;

    _adEventBuffer.add(_AdEvent(
      installId: _installId!,
      code: code.toUpperCase(),
      adFormat: adFormat,
      valueMicros: valueMicros,
      currency: currency,
      precision: precision,
    ));

    if (_adEventBuffer.length >= AppConstants.attributionBatchSize) {
      _flushAdEvents();
    } else if (_flushTimer == null) {
      _flushTimer = Timer(
        Duration(milliseconds: AppConstants.attributionFlushIntervalMs),
        _flushAdEvents,
      );
    }
  }

  void _flushAdEvents() {
    _flushTimer?.cancel();
    _flushTimer = null;

    if (_adEventBuffer.isEmpty) return;

    final batch = List<_AdEvent>.from(_adEventBuffer);
    _adEventBuffer.clear();

    _post('/v1/events/ad', {
      'events': batch.map((e) => e.toJson()).toList(),
    });
  }

  /// Log a daily retention ping. Called once per app launch.
  Future<void> logDailyPing() async {
    if (!_canSend || _referralCode == null) return;

    await _post('/v1/events/ping', {
      'installId': _installId,
      'code': _referralCode,
    });
  }
}
