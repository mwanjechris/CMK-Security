class AppConstants {
  static const String appName = 'CMK Security';
  static const String packageName = 'com.cmk.cmk_security';

  // Storage keys
  static const String keyLockType = 'lock_type';
  static const String keyPinHash = 'pin_hash';
  static const String keyPatternHash = 'pattern_hash';
  static const String keyLockedApps = 'locked_apps';
  static const String keyHiddenApps = 'hidden_apps';
  static const String keyLockedFiles = 'locked_files';
  static const String keySetupComplete = 'setup_complete';
  static const String keyVaultPassword = 'vault_password';

  // Method channel
  static const String methodChannel = 'com.cmk.cmk_security/app_lock';
  static const String methodGetInstalledApps = 'getInstalledApps';
  static const String methodLaunchApp = 'launchApp';
  static const String methodStartMonitor = 'startMonitorService';
  static const String methodStopMonitor = 'stopMonitorService';
  static const String methodUpdateLockedApps = 'updateLockedApps';
  static const String methodHasUsagePermission = 'hasUsagePermission';
  static const String methodRequestUsagePermission = 'requestUsagePermission';
  static const String methodHasOverlayPermission = 'hasOverlayPermission';
  static const String methodRequestOverlayPermission = 'requestOverlayPermission';
  static const String methodGetAppIcon = 'getAppIcon';

  // PIN settings
  static const int pinMinLength = 4;
  static const int pinMaxLength = 6;

  // Pattern settings
  static const int patternMinDots = 4;
}
