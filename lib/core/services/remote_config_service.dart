import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._();

  late final FirebaseRemoteConfig _remoteConfig;

  Future<void> initialize() async {
    _remoteConfig = FirebaseRemoteConfig.instance;

    // Set default values (fallback)
    await _remoteConfig.setDefaults({
      'opencode_zen_api_key': '', // Empty default - fallback to build-time key
      'ai_coach_enabled': true,
    });

    // Fetch remote values (cache for 1 hour in production, 0 for testing)
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      print('Remote Config fetch failed: $e');
    }
  }

  /// Get OpenCode Zen API key from Remote Config (or empty if not set)
  String getOpenCodeZenApiKey() {
    return _remoteConfig.getString('opencode_zen_api_key');
  }

  /// Check if AI Coach is enabled
  bool isAiCoachEnabled() {
    return _remoteConfig.getBool('ai_coach_enabled');
  }
}
