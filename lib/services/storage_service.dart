import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/lock_type.dart';
import '../models/locked_app.dart';
import '../models/locked_file.dart';

class StorageService {
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Lock type ──────────────────────────────────────────────
  Future<LockType?> getLockType() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(AppConstants.keyLockType);
    if (val == null) return null;
    return LockType.fromJson(val);
  }

  Future<void> saveLockType(LockType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLockType, type.toJson());
  }

  // ── Setup complete ─────────────────────────────────────────
  Future<bool> isSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keySetupComplete) ?? false;
  }

  Future<void> markSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keySetupComplete, true);
  }

  // ── PIN ───────────────────────────────────────────────────
  Future<void> savePin(String hashedPin) async {
    await _secure.write(key: AppConstants.keyPinHash, value: hashedPin);
  }

  Future<String?> getPin() async {
    return _secure.read(key: AppConstants.keyPinHash);
  }

  Future<void> deletePin() async {
    await _secure.delete(key: AppConstants.keyPinHash);
  }

  // ── Pattern ───────────────────────────────────────────────
  Future<void> savePattern(String hashedPattern) async {
    await _secure.write(key: AppConstants.keyPatternHash, value: hashedPattern);
  }

  Future<String?> getPattern() async {
    return _secure.read(key: AppConstants.keyPatternHash);
  }

  Future<void> deletePattern() async {
    await _secure.delete(key: AppConstants.keyPatternHash);
  }

  // ── Locked Apps ───────────────────────────────────────────
  Future<List<LockedApp>> getLockedApps() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(AppConstants.keyLockedApps);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => LockedApp.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveLockedApps(List<LockedApp> apps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.keyLockedApps,
      jsonEncode(apps.map((e) => e.toJson()).toList()),
    );
  }

  // ── Locked Files ──────────────────────────────────────────
  Future<List<LockedFile>> getLockedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(AppConstants.keyLockedFiles);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => LockedFile.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveLockedFiles(List<LockedFile> files) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.keyLockedFiles,
      jsonEncode(files.map((e) => e.toJson()).toList()),
    );
  }

  // ── Clear all ─────────────────────────────────────────────
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _secure.deleteAll();
  }
}
