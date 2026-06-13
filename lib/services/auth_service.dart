import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import '../models/lock_type.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storage;
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthService(this._storage);

  String _hash(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  // ── PIN ───────────────────────────────────────────────────
  Future<void> setPin(String pin) async {
    await _storage.savePin(_hash(pin));
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.getPin();
    if (stored == null) return false;
    return stored == _hash(pin);
  }

  // ── Pattern ───────────────────────────────────────────────
  Future<void> setPattern(List<int> pattern) async {
    final key = pattern.join('-');
    await _storage.savePattern(_hash(key));
  }

  Future<bool> verifyPattern(List<int> pattern) async {
    final stored = await _storage.getPattern();
    if (stored == null) return false;
    final key = pattern.join('-');
    return stored == _hash(key);
  }

  // ── Biometric ─────────────────────────────────────────────
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isAvailable = await _localAuth.isDeviceSupported();
      return canCheck && isAvailable;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
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
}
