import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Communicates with the native iOS AppDelegate via a method channel.
/// Used for battery level, device model, Low Power Mode, etc.
class NativeChannelService {
  static const _channel = MethodChannel('com.odctracker/native');
  static final NativeChannelService _instance =
      NativeChannelService._internal();
  factory NativeChannelService() => _instance;
  NativeChannelService._internal();

  /// Returns battery level 0–100, or -1 if unavailable / web.
  Future<int> getBatteryLevel() async {
    if (kIsWeb || !Platform.isIOS) return -1;
    try {
      return await _channel.invokeMethod<int>('getBatteryLevel') ?? -1;
    } catch (_) {
      return -1;
    }
  }

  /// Returns the iOS device model string, e.g. "iPhone" or "iPad".
  Future<String> getDeviceModel() async {
    if (kIsWeb || !Platform.isIOS) return '';
    try {
      return await _channel.invokeMethod<String>('getDeviceModel') ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Returns "16.4", "17.0" etc.
  Future<String> getSystemVersion() async {
    if (kIsWeb || !Platform.isIOS) return '';
    try {
      return await _channel.invokeMethod<String>('getSystemVersion') ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Returns true if iOS Low Power Mode is active.
  Future<bool> isLowPowerMode() async {
    if (kIsWeb || !Platform.isIOS) return false;
    try {
      return await _channel.invokeMethod<bool>('isLowPowerMode') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Returns the device's given name, e.g. "Preetham's iPhone".
  Future<String> getDeviceName() async {
    if (kIsWeb || !Platform.isIOS) return '';
    try {
      return await _channel.invokeMethod<String>('getDeviceName') ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Sets up a handler for deep links sent by the native layer.
  /// [onLink] receives the full URL string, e.g. "odctracker://checkin".
  void listenForDeepLinks(void Function(String url) onLink) {
    if (kIsWeb) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'deepLink' || call.method == 'universalLink') {
        final url = call.arguments as String?;
        if (url != null) onLink(url);
      }
    });
  }
}
