import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';
import '../models/locked_app.dart';

class PlatformService {
  static const _channel = MethodChannel(AppConstants.methodChannel);

  Future<List<InstalledApp>> getInstalledApps() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod(
        AppConstants.methodGetInstalledApps,
      );
      return result
          .map((e) => InstalledApp.fromMap(e as Map<dynamic, dynamic>))
          .where((app) => app.packageName != AppConstants.packageName)
          .toList()
        ..sort((a, b) => a.appName.compareTo(b.appName));
    } on PlatformException {
      return [];
    }
  }

  Future<void> launchApp(String packageName) async {
    try {
      await _channel.invokeMethod(
        AppConstants.methodLaunchApp,
        {'packageName': packageName},
      );
    } on PlatformException {
      rethrow;
    }
  }

  Future<bool> hasUsageStatsPermission() async {
    try {
      return await _channel.invokeMethod(AppConstants.methodHasUsagePermission) ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> requestUsageStatsPermission() async {
    try {
      await _channel.invokeMethod(AppConstants.methodRequestUsagePermission);
    } on PlatformException {
      rethrow;
    }
  }

  Future<bool> hasOverlayPermission() async {
    try {
      return await _channel.invokeMethod(AppConstants.methodHasOverlayPermission) ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod(AppConstants.methodRequestOverlayPermission);
    } on PlatformException {
      rethrow;
    }
  }

  Future<void> startMonitorService(List<String> lockedPackages) async {
    try {
      await _channel.invokeMethod(
        AppConstants.methodStartMonitor,
        {'packages': lockedPackages},
      );
    } on PlatformException catch (_) {}
  }

  Future<void> stopMonitorService() async {
    try {
      await _channel.invokeMethod(AppConstants.methodStopMonitor);
    } on PlatformException catch (_) {}
  }

  Future<void> updateLockedApps(List<String> lockedPackages) async {
    try {
      await _channel.invokeMethod(
        AppConstants.methodUpdateLockedApps,
        {'packages': lockedPackages},
      );
    } on PlatformException catch (_) {}
  }

  // Write lock credentials to native SharedPreferences so the
  // NativeLockScreenActivity can validate auth without Flutter engine
  Future<void> setLockCredentials(String lockType, String hash) async {
    try {
      await _channel.invokeMethod(
        AppConstants.methodSetLockCredentials,
        {'lockType': lockType, 'hash': hash},
      );
    } on PlatformException catch (_) {}
  }

  // Signal the native lock screen that auth succeeded for this package
  Future<void> notifyAuthSuccess(String packageName) async {
    try {
      await _channel.invokeMethod(
        AppConstants.methodNotifyAuthSuccess,
        {'packageName': packageName},
      );
    } on PlatformException catch (_) {}
  }
}
