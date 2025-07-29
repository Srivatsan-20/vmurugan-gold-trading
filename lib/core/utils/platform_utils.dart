// =====================================================
// Platform Utils - Web-Compatible Platform Detection
// =====================================================

import 'package:flutter/foundation.dart';

class PlatformUtils {
  // Get platform name in a web-compatible way
  static String get platformName {
    if (kIsWeb) {
      return 'web';
    } else {
      // For non-web platforms, we can use conditional imports
      // For now, return a generic name
      return _getNativePlatformName();
    }
  }

  // Get platform-specific information
  static Map<String, dynamic> getPlatformInfo() {
    return {
      'platform': platformName,
      'is_web': kIsWeb,
      'is_mobile': !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS),
      'is_desktop': !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux),
      'target_platform': defaultTargetPlatform.toString(),
      'debug_mode': kDebugMode,
      'profile_mode': kProfileMode,
      'release_mode': kReleaseMode,
    };
  }

  // Generate a device ID that works across platforms
  static String generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final platform = platformName;
    return '${platform}_device_$timestamp';
  }

  // Private method to get native platform name
  static String _getNativePlatformName() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
      default:
        return 'unknown';
    }
  }

  // Check if running on mobile
  static bool get isMobile {
    return !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  }

  // Check if running on desktop
  static bool get isDesktop {
    return !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux);
  }

  // Get user agent string for web
  static String getUserAgent() {
    if (kIsWeb) {
      return 'VMUrugan-Gold-Trading-Web/1.0.0';
    } else {
      return 'VMUrugan-Gold-Trading-${platformName}/1.0.0';
    }
  }
}
