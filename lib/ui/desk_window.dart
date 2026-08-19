import 'package:flutter/services.dart';

class DeskWindow {
  static const _ch = MethodChannel('netchecker/window');

  static Future<void> setAlwaysOnTop(bool on) async {
    try {
      await _ch.invokeMethod<void>('setAlwaysOnTop', on);
    } catch (_) {}
  }

  static Future<void> setCompact(bool on) async {
    try {
      await _ch.invokeMethod<void>('setCompact', on);
    } catch (_) {}
  }
}
