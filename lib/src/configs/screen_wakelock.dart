import 'dart:io';

import 'package:flutter/services.dart';

/// Keeps the screen awake while transfers are active on mobile platforms.
///
/// Uses the `quarkdrop/background` method channel which is handled natively
/// on Android (FLAG_KEEP_SCREEN_ON) and iOS (isIdleTimerDisabled).
class ScreenWakelock {
  static const _channel = MethodChannel('quarkdrop/background');
  static bool _keepingOn = false;

  static bool get isMobile => Platform.isAndroid || Platform.isIOS;

  static Future<void> setKeepScreenOn(bool value) async {
    if (!isMobile) return;
    if (_keepingOn == value) return;
    _keepingOn = value;
    try {
      await _channel.invokeMethod('setKeepScreenOn', value);
    } catch (_) {}
  }
}
