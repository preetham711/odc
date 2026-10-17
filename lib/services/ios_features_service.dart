import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Central service for all advanced Apple/iOS platform features.
/// Every method safely no-ops on non-iOS platforms.
class IOSFeaturesService {
  static final IOSFeaturesService _instance = IOSFeaturesService._internal();
  factory IOSFeaturesService() => _instance;
  IOSFeaturesService._internal();

  final _auth = LocalAuthentication();
  final _review = InAppReview.instance;

  // ─── Biometrics (Face ID / Touch ID) ─────────────────────────────────────

  /// Returns true if the device supports biometric authentication.
  Future<bool> canUseBiometrics() async {
    if (kIsWeb) return false;
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Returns the type of biometric available: 'faceID', 'touchID', or 'none'.
  Future<String> biometricType() async {
    if (kIsWeb) return 'none';
    try {
      final available = await _auth.getAvailableBiometrics();
      if (available.contains(BiometricType.face)) return 'faceID';
      if (available.contains(BiometricType.fingerprint)) return 'touchID';
      return 'none';
    } catch (_) {
      return 'none';
    }
  }

  /// Authenticate using Face ID / Touch ID.
  /// Returns true if authenticated successfully.
  Future<bool> authenticate({String reason = 'Unlock ODC Tracker AI'}) async {
    if (kIsWeb) return true;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // allow PIN fallback
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric auth error: ${e.code} — ${e.message}');
      return false;
    }
  }

  // ─── Haptic Engine ────────────────────────────────────────────────────────

  /// Heavy impact — used for I'M IN (return from break).
  static void heavyImpact() =>
      HapticFeedback.heavyImpact();

  /// Medium impact — used for I'M OUT, button presses.
  static void mediumImpact() =>
      HapticFeedback.mediumImpact();

  /// Light impact — used for navigation, selection.
  static void lightImpact() =>
      HapticFeedback.lightImpact();

  /// Selection changed — used for tab bar, segmented control.
  static void selectionClick() =>
      HapticFeedback.selectionClick();

  /// Success pattern — UINotificationFeedbackType.success equivalent.
  static Future<void> successFeedback() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.lightImpact();
  }

  /// Error pattern — UINotificationFeedbackType.error equivalent.
  static Future<void> errorFeedback() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
  }

  /// Warning pattern — UINotificationFeedbackType.warning equivalent.
  static Future<void> warningFeedback() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }

  // ─── App Store Review ─────────────────────────────────────────────────────

  /// Request an App Store review at an appropriate moment.
  /// Automatically throttled by the OS — won't show if shown recently.
  Future<void> requestReview() async {
    if (kIsWeb) return;
    try {
      if (await _review.isAvailable()) {
        await _review.requestReview();
      }
    } catch (_) {}
  }

  /// Open the App Store page for ODC Tracker AI.
  Future<void> openAppStorePage() async {
    if (kIsWeb) return;
    try {
      await _review.openStoreListing();
    } catch (_) {}
  }

  // ─── Native Share Sheet ───────────────────────────────────────────────────

  /// Share text content using the native iOS/Android share sheet.
  static Future<void> shareText(String text, {String? subject}) async {
    try {
      await Share.share(text, subject: subject);
    } catch (_) {}
  }

  /// Share an attendance summary report as text.
  static Future<void> shareAttendanceSummary({
    required String date,
    required String odcTime,
    required String breakTime,
    required String completion,
  }) async {
    final text = '''📊 ODC Tracker — Daily Report
Date: $date
ODC Time: $odcTime
Break Time: $breakTime  
Completion: $completion

Tracked with ODC Tracker AI''';
    await shareText(text, subject: 'My ODC Report — $date');
  }

  // ─── URL Launcher ────────────────────────────────────────────────────────

  static Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> sendEmail({
    required String to,
    String subject = '',
    String body = '',
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: to,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ─── Device Info ─────────────────────────────────────────────────────────

  Future<Map<String, String>> getDeviceInfo() async {
    if (kIsWeb) {
      return {'platform': 'web', 'model': 'Browser'};
    }
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        return {
          'platform': 'iOS',
          'model': info.model,
          'systemVersion': info.systemVersion,
          'name': info.name,
          'isPhysicalDevice': info.isPhysicalDevice.toString(),
        };
      } else if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return {
          'platform': 'Android',
          'model': info.model,
          'version': info.version.release,
          'manufacturer': info.manufacturer,
        };
      }
      return {'platform': 'unknown'};
    } catch (_) {
      return {'platform': 'unknown'};
    }
  }

  // ─── App Info ─────────────────────────────────────────────────────────────

  Future<Map<String, String>> getAppInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return {
        'name': info.appName,
        'version': info.version,
        'buildNumber': info.buildNumber,
        'packageName': info.packageName,
      };
    } catch (_) {
      return {'version': '1.2.0', 'buildNumber': '12'};
    }
  }

  // ─── iOS Status Bar ───────────────────────────────────────────────────────

  static void setStatusBarLight() {
    if (kIsWeb) return;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0x00000000),
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
  }

  static void setStatusBarDark() {
    if (kIsWeb) return;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0x00000000),
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
  }
}
