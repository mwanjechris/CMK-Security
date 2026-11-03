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
                  itemBuilder: (context, i) => _AppTile(app: filtered[i]),
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
        subtitle: isHidden
            ? const Text(
                'In Vault — remove icon manually from home screen',
                style: TextStyle(color: AppTheme.warning, fontSize: 11),
              )
            : Text(
                app.packageName,
                style: const TextStyle(color: Color(0xFF555577), fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLocked)
              IconButton(
                onPressed: () => _toggleHidden(context, ref, isHidden),
                tooltip: isHidden ? 'Show in launcher' : 'Move to Vault',
                icon: Icon(
                  isHidden ? Icons.visibility_off_rounded : Icons.inventory_2_outlined,
                  color: isHidden ? AppTheme.warning : const Color(0xFF666688),
                  size: 20,
                ),
              ),
            Switch(
              value: isLocked,
              onChanged: (_) async {
                if (isLocked) {
                  await notifier.unlockApp(app.packageName);
                } else {
                  await notifier.lockApp(app.packageName, app.appName);
                  _showLockServiceReminder(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLockServiceReminder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('App locked. Grant Usage Access & Overlay permissions for the lock screen to appear.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _toggleHidden(BuildContext context, WidgetRef ref, bool currentlyHidden) {
    final notifier = ref.read(lockedAppsProvider.notifier);
    if (currentlyHidden) {
      // Un-hiding
      notifier.toggleHidden(app.packageName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${app.appName} removed from Vault.')),
      );
    } else {
      // Hiding — show instructions
      showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.surfaceVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _HideGuideSheet(app: app, notifier: notifier),
      );
    }
  }
}

class _HideGuideSheet extends StatelessWidget {
  final InstalledApp app;
  final LockedAppsNotifier notifier;

  const _HideGuideSheet({required this.app, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_rounded, color: AppTheme.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'Move "${app.appName}" to Vault',
                style: const TextStyle(
                  color: AppTheme.onBackground,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Android does not allow third-party apps to hide icons from your launcher. Here\'s how to do it manually:',
            style: TextStyle(color: Color(0xFF888899), fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 16),
          _Step(number: '1', text: 'Long-press the app icon on your home screen'),
          _Step(number: '2', text: 'Tap "Remove" or drag it to the trash (this only hides it from home screen, the app still works)'),
          _Step(number: '3', text: 'Access the app anytime through CMK Security → Vault'),
          const SizedBox(height: 20),
          const Text(
            'Tap "Move to Vault" below to track this app in your CMK Security Vault.',
            style: TextStyle(color: Color(0xFF666688), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    notifier.toggleHidden(app.packageName);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${app.appName} is now in your Vault.'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  },
                  icon: const Icon(Icons.inventory_2_rounded, size: 18),
                  label: const Text('Move to Vault'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;
  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppTheme.onSurface, fontSize: 13, height: 1.4),
            ),
          ),
        ],
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
