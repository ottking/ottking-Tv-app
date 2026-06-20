// lib/core/constants/app_constants.dart

class AppConstants {
  const AppConstants._();

  static const String appName     = 'OTTKing';
  static const String appTagline  = 'Professional Smart TV Streaming';

  // API
  static const String defaultApiBaseUrl = 'https://verify-app.alwaysdata.net/api2';

  // Security
  static const String apiKeyId       = 'ottking-mobile';
  static const String hmacSecret     = 'ottking-hmac-secret-2026';
  static const String encryptionKey  = 'ottking_secure_32byte_key_2026AB'; // must be 32 chars

  // Player
  static const String fallbackStreamUrl =
      'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8';

  // Timing
  static const Duration splashDuration  = Duration(seconds: 3);
  static const Duration toastDuration   = Duration(seconds: 3);
  static const int requestTimestampToleranceSeconds = 300;

  // Boot player storage key
  static const String keyBootToPlayer  = 'bootToPlayer';
  static const String keyLastChannelId = 'lastChannelId';
  static const String keyThemeMode     = 'themeMode';
}
