import 'package:flutter/foundation.dart';

enum AppPlatform {
  android,
  ios,
  web,
  windows,
  macOS,
  linux,
  unknown,
}

class PlatformDetector {
  PlatformDetector._();

  static AppPlatform get current {
    if (kIsWeb) return AppPlatform.web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AppPlatform.android;
      case TargetPlatform.iOS:
        return AppPlatform.ios;
      case TargetPlatform.windows:
        return AppPlatform.windows;
      case TargetPlatform.macOS:
        return AppPlatform.macOS;
      case TargetPlatform.linux:
        return AppPlatform.linux;
      default:
        return AppPlatform.unknown;
    }
  }

  static bool get isWeb => current == AppPlatform.web;

  static bool get isMobile =>
      current == AppPlatform.android || current == AppPlatform.ios;

  static bool get isDesktop =>
      current == AppPlatform.windows ||
          current == AppPlatform.macOS ||
          current == AppPlatform.linux;

  static bool get supportsWindowControls => isDesktop;
}