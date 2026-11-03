import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import '../models/lock_type.dart';
import 'platform_service.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storage;
  final PlatformService _platform;
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthService(this._storage, this._platform);

  String _hash(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  // ── PIN ───────────────────────────────────────────────────
  Future<void> setPin(String pin) async {
    final hash = _hash(pin);
    await _storage.savePin(hash);
    // Write to native prefs so NativeLockScreenActivity can validate
    await _platform.setLockCredentials('pin', hash);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.getPin();
    if (stored == null) return false;
    return stored == _hash(pin);
  }

  // ── Pattern ───────────────────────────────────────────────
  Future<void> setPattern(List<int> pattern) async {
    final key = pattern.join('-');
    final hash = _hash(key);
    await _storage.savePattern(hash);
    await _platform.setLockCredentials('pattern', hash);
  }

  Future<bool> verifyPattern(List<int> pattern) async {
    final stored = await _storage.getPattern();
    if (stored == null) return false;
    final key = pattern.join('-');
    return stored == _hash(key);
  }

  // ── Biometric ─────────────────────────────────────────────
  Future<void> setBiometric() async {
    // For biometric, we store a sentinel hash; actual auth is done by the OS
    await _platform.setLockCredentials('biometric', 'biometric_enabled');
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isAvailable = await _localAuth.isDeviceSupported();
      return canCheck && isAvailable;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access CMK Security',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ── Generic verify by type ────────────────────────────────
  Future<bool> authenticate(LockType type, {String? pin, List<int>? pattern}) async {
    switch (type) {
      case LockType.pin:
        if (pin == null) return false;
        return verifyPin(pin);
      case LockType.pattern:
        if (pattern == null) return false;
        return verifyPattern(pattern);
      case LockType.biometric:
        return authenticateWithBiometric();
    }
  }

  String hashPin(String pin) => _hash(pin);
  String hashPattern(List<int> pattern) => _hash(pattern.join('-'));
}
