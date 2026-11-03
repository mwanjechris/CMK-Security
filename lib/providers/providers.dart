import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lock_type.dart';
import '../models/locked_app.dart';
import '../models/locked_file.dart';
import '../services/auth_service.dart';
import '../services/file_vault_service.dart';
import '../services/platform_service.dart';
import '../services/storage_service.dart';

// ── Service providers ──────────────────────────────────────
final storageServiceProvider = Provider<StorageService>((_) => StorageService());

final platformServiceProvider = Provider<PlatformService>((_) => PlatformService());

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.read(storageServiceProvider),
    ref.read(platformServiceProvider),
  );
});

final fileVaultServiceProvider = Provider<FileVaultService>((ref) {
  return FileVaultService(ref.read(storageServiceProvider));
});

// ── Setup state ────────────────────────────────────────────
final setupCompleteProvider = FutureProvider<bool>((ref) {
  return ref.read(storageServiceProvider).isSetupComplete();
});

// ── Lock type ──────────────────────────────────────────────
final lockTypeProvider = StateNotifierProvider<LockTypeNotifier, AsyncValue<LockType?>>((ref) {
  return LockTypeNotifier(ref.read(storageServiceProvider));
});

class LockTypeNotifier extends StateNotifier<AsyncValue<LockType?>> {
  final StorageService _storage;

  LockTypeNotifier(this._storage) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = AsyncValue.data(await _storage.getLockType());
  }

  Future<void> setLockType(LockType type) async {
    await _storage.saveLockType(type);
    state = AsyncValue.data(type);
  }
}

// ── Installed apps ─────────────────────────────────────────
final installedAppsProvider = FutureProvider<List<InstalledApp>>((ref) {
  return ref.read(platformServiceProvider).getInstalledApps();
});

// ── Locked apps ────────────────────────────────────────────
final lockedAppsProvider = StateNotifierProvider<LockedAppsNotifier, AsyncValue<List<LockedApp>>>((ref) {
  return LockedAppsNotifier(
    ref.read(storageServiceProvider),
    ref.read(platformServiceProvider),
  );
});

class LockedAppsNotifier extends StateNotifier<AsyncValue<List<LockedApp>>> {
  final StorageService _storage;
  final PlatformService _platform;

  LockedAppsNotifier(this._storage, this._platform) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    final apps = await _storage.getLockedApps();
    state = AsyncValue.data(apps);
    // Auto-start the monitor service if there are already locked apps
    if (apps.isNotEmpty) {
      await _platform.startMonitorService(apps.map((a) => a.packageName).toList());
    }
  }

  Future<void> lockApp(String packageName, String appName) async {
    final current = state.valueOrNull ?? [];
    if (current.any((a) => a.packageName == packageName)) return;
    final updated = [
      ...current,
      LockedApp(packageName: packageName, appName: appName, lockedAt: DateTime.now()),
    ];
    await _storage.saveLockedApps(updated);
    state = AsyncValue.data(updated);
    // Always start (or update) the monitor service
    await _platform.startMonitorService(updated.map((a) => a.packageName).toList());
  }

  Future<void> unlockApp(String packageName) async {
    final current = state.valueOrNull ?? [];
    final updated = current.where((a) => a.packageName != packageName).toList();
    await _storage.saveLockedApps(updated);
    state = AsyncValue.data(updated);
    if (updated.isEmpty) {
      await _platform.stopMonitorService();
    } else {
      await _platform.startMonitorService(updated.map((a) => a.packageName).toList());
    }
  }

  Future<void> toggleHidden(String packageName) async {
    final current = state.valueOrNull ?? [];
    final updated = current.map((a) {
      if (a.packageName == packageName) return a.copyWith(isHidden: !a.isHidden);
      return a;
    }).toList();
    await _storage.saveLockedApps(updated);
    state = AsyncValue.data(updated);
  }

  bool isLocked(String packageName) {
    return state.valueOrNull?.any((a) => a.packageName == packageName) ?? false;
  }

  bool isHidden(String packageName) {
    return state.valueOrNull?.any((a) => a.packageName == packageName && a.isHidden) ?? false;
  }
}

// ── Locked files ───────────────────────────────────────────
final lockedFilesProvider = StateNotifierProvider<LockedFilesNotifier, AsyncValue<List<LockedFile>>>((ref) {
  return LockedFilesNotifier(
    ref.read(storageServiceProvider),
    ref.read(fileVaultServiceProvider),
  );
});

class LockedFilesNotifier extends StateNotifier<AsyncValue<List<LockedFile>>> {
  final StorageService _storage;
  final FileVaultService _vault;

  LockedFilesNotifier(this._storage, this._vault) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = AsyncValue.data(await _storage.getLockedFiles());
  }

  Future<void> lockFile(String path) async {
    state = const AsyncValue.loading();
    try {
      await _vault.lockFile(path);
      final current = await _storage.getLockedFiles();
      state = AsyncValue.data(current);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String> unlockFile(LockedFile file, String destinationDir) async {
    final path = await _vault.unlockFile(file, destinationDir);
    await _vault.removeFromVault(file);
    final current = await _storage.getLockedFiles();
    state = AsyncValue.data(current);
    return path;
  }

  Future<void> removeFile(LockedFile file) async {
    await _vault.removeFromVault(file);
    final current = await _storage.getLockedFiles();
    state = AsyncValue.data(current);
  }
}

// ── Permissions ────────────────────────────────────────────
final permissionsProvider = StateNotifierProvider<PermissionsNotifier, PermissionsState>((ref) {
  return PermissionsNotifier(ref.read(platformServiceProvider));
});

class PermissionsState {
  final bool hasUsageStats;
  final bool hasOverlay;

  const PermissionsState({this.hasUsageStats = false, this.hasOverlay = false});

  PermissionsState copyWith({bool? hasUsageStats, bool? hasOverlay}) {
    return PermissionsState(
      hasUsageStats: hasUsageStats ?? this.hasUsageStats,
      hasOverlay: hasOverlay ?? this.hasOverlay,
    );
  }

  bool get allGranted => hasUsageStats && hasOverlay;
}

class PermissionsNotifier extends StateNotifier<PermissionsState> {
  final PlatformService _platform;

  PermissionsNotifier(this._platform) : super(const PermissionsState()) {
    check();
  }

  Future<void> check() async {
    final usage = await _platform.hasUsageStatsPermission();
    final overlay = await _platform.hasOverlayPermission();
    state = PermissionsState(hasUsageStats: usage, hasOverlay: overlay);
  }

  Future<void> requestUsageStats() async {
    await _platform.requestUsageStatsPermission();
    await check();
  }

  Future<void> requestOverlay() async {
    await _platform.requestOverlayPermission();
    await check();
  }
}
