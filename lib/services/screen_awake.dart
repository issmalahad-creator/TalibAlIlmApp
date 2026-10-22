import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the screen on while a reading screen is open (the muṣḥaf, a Turath
/// book). Android's `FLAG_KEEP_SCREEN_ON` on the activity window: no
/// permission, no wakelock, nothing left running once the flag is cleared.
/// Reading screens can stack (a Turath book opened from the reader), so
/// holders are counted and the flag drops only when the last one leaves.
class ScreenAwake {
  ScreenAwake._();

  static const prefKey = 'keep_screen_on_reading';
  static const _channel = MethodChannel('talib_alilm/screen');
  static int _holders = 0;
  static bool? _enabled;

  static Future<bool> isEnabled() async {
    return _enabled ??= (await SharedPreferences.getInstance()).getBool(prefKey) ?? true;
  }

  static Future<void> setEnabled(bool v) async {
    _enabled = v;
    await (await SharedPreferences.getInstance()).setBool(prefKey, v);
    await _apply();
  }

  static Future<void> acquire() async {
    _holders++;
    await _apply();
  }

  static Future<void> release() async {
    if (_holders > 0) _holders--;
    await _apply();
  }

  static Future<void> _apply() async {
    final on = _holders > 0 && await isEnabled();
    try {
      await _channel.invokeMethod<void>('keepOn', on);
    } on MissingPluginException {
      // Not Android (or a test): the screen simply follows the system timeout.
    } on PlatformException {
      // Same: never let a cosmetic flag break reading.
    }
  }
}
