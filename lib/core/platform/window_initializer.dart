import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'platform_detector.dart';

class WindowInitializer {
  WindowInitializer._();

  static Future<void> initialize() async {
    if (PlatformDetector.isDesktop) {
      await _initDesktop();
    } else if (PlatformDetector.isMobile) {
      await _initMobile();
    }
  }

  static Future<void> _initDesktop() async {
    await windowManager.ensureInitialized();

    const WindowOptions options = WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(720, 560),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      fullScreen: false,
    );

    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  static Future<void> _initMobile() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
    await SystemChrome.setPreferredOrientations(
      <DeviceOrientation>[
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
    );
  }
}