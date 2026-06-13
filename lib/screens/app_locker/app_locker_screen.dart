import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/locked_app.dart';
import '../../providers/providers.dart';

class AppLockerScreen extends ConsumerStatefulWidget {
  const AppLockerScreen({super.key});

  @override
  ConsumerState<AppLockerScreen> createState() => _AppLockerScreenState();
}

class _AppLockerScreenState extends ConsumerState<AppLockerScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final installedAsync = ref.watch(installedAppsProvider);
    final lockedAppsAsync = ref.watch(lockedAppsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('App Locker'),
        backgroundColor: AppTheme.background,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              backgroundColor: AppTheme.primary.withAlpha(30),
              label: Text(
                '${lockedAppsAsync.valueOrNull?.length ?? 0} locked',
                style: const TextStyle(color: AppTheme.primary, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search apps...',
                prefixIcon: Icon(Icons.search, color: Color(0xFF555577)),
              ),
            ),
          ),
          Expanded(
            child: installedAsync.when(
              loading: () => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading apps...', style: TextStyle(color: Color(0xFF888899))),
                  ],
                ),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                    const SizedBox(height: 16),
                    Text('$e', style: const TextStyle(color: Color(0xFF888899))),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(installedAppsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (apps) {
                final filtered = _search.isEmpty
                    ? apps
                    : apps.where((a) => a.appName.toLowerCase().contains(_search)).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No apps found', style: TextStyle(color: Color(0xFF888899))),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final app = filtered[i];
                    return _AppTile(app: app);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AppTile extends ConsumerWidget {
  final InstalledApp app;

  const _AppTile({required this.app});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(lockedAppsProvider);
    final notifier = ref.read(lockedAppsProvider.notifier);
    final isLocked = notifier.isLocked(app.packageName);
    final isHidden = notifier.isHidden(app.packageName);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLocked ? AppTheme.primary.withAlpha(60) : AppTheme.divider,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _AppIcon(iconBytes: app.iconBytes),
        title: Text(
          app.appName,
          style: const TextStyle(
            color: AppTheme.onBackground,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          app.packageName,
          style: const TextStyle(color: Color(0xFF555577), fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLocked) ...[
              IconButton(
                onPressed: () => notifier.toggleHidden(app.packageName),
                tooltip: isHidden ? 'Show icon' : 'Hide icon',
                icon: Icon(
                  isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: isHidden ? AppTheme.warning : const Color(0xFF666688),
                  size: 20,
                ),
              ),
            ],
            Switch(
              value: isLocked,
              onChanged: (_) async {
                if (isLocked) {
                  await notifier.unlockApp(app.packageName);
                } else {
                  await notifier.lockApp(app.packageName, app.appName);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  final List<int>? iconBytes;

  const _AppIcon({this.iconBytes});

  @override
  Widget build(BuildContext context) {
    if (iconBytes != null && iconBytes!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          Uint8List.fromList(iconBytes!),
          width: 44,
          height: 44,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.android, color: AppTheme.primary, size: 28),
    );
  }
}
