import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/locked_app.dart';
import '../../providers/providers.dart';

class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockedAppsAsync = ref.watch(lockedAppsProvider);
    final installedAsync = ref.watch(installedAppsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Vault'),
        backgroundColor: AppTheme.background,
      ),
      body: lockedAppsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (lockedApps) {
          final hiddenApps = lockedApps.where((a) => a.isHidden).toList();

          if (hiddenApps.isEmpty) {
            return _EmptyVault();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(
                  '${hiddenApps.length} hidden app${hiddenApps.length != 1 ? 's' : ''}',
                  style: const TextStyle(color: Color(0xFF888899), fontSize: 14),
                ),
              ),
              Expanded(
                child: installedAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => _VaultAppGrid(hiddenApps: hiddenApps, installedApps: []),
                  data: (installed) => _VaultAppGrid(
                    hiddenApps: hiddenApps,
                    installedApps: installed,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VaultAppGrid extends ConsumerWidget {
  final List<LockedApp> hiddenApps;
  final List<InstalledApp> installedApps;

  const _VaultAppGrid({required this.hiddenApps, required this.installedApps});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platform = ref.read(platformServiceProvider);

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.8,
      ),
      itemCount: hiddenApps.length,
      itemBuilder: (context, i) {
        final lockedApp = hiddenApps[i];
        final installed = installedApps.firstWhere(
          (a) => a.packageName == lockedApp.packageName,
          orElse: () => InstalledApp(
            packageName: lockedApp.packageName,
            appName: lockedApp.appName,
          ),
        );
        return _VaultAppItem(
          lockedApp: lockedApp,
          installedApp: installed,
          onLaunch: () async {
            try {
              await platform.launchApp(lockedApp.packageName);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not launch ${lockedApp.appName}')),
                );
              }
            }
          },
        );
      },
    );
  }
}

class _VaultAppItem extends StatelessWidget {
  final LockedApp lockedApp;
  final InstalledApp installedApp;
  final VoidCallback onLaunch;

  const _VaultAppItem({
    required this.lockedApp,
    required this.installedApp,
    required this.onLaunch,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onLaunch,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.primary.withAlpha(60)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withAlpha(30),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: installedApp.iconBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      Uint8List.fromList(installedApp.iconBytes!),
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.android, color: AppTheme.primary, size: 40),
          ),
          const SizedBox(height: 8),
          Text(
            lockedApp.appName,
            style: const TextStyle(
              color: AppTheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EmptyVault extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primary, size: 56),
            ),
            const SizedBox(height: 24),
            const Text(
              'Vault is Empty',
              style: TextStyle(
                color: AppTheme.onBackground,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hide apps from App Locker by toggling the eye icon. They\'ll appear here, accessible only through CMK Security.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF888899), fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
