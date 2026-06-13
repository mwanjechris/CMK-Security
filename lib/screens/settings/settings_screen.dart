import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lock_type.dart';
import '../../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockTypeAsync = ref.watch(lockTypeProvider);
    final perms = ref.watch(permissionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.background,
      ),
      body: ListView(
        children: [
          _SectionHeader(label: 'LOCK CONFIGURATION'),
          lockTypeAsync.when(
            loading: () => const ListTile(title: Text('Loading...')),
            error: (_, __) => const ListTile(title: Text('Error')),
            data: (type) => _SettingsTile(
              icon: Icons.lock_outline_rounded,
              title: 'Lock Type',
              subtitle: type?.label ?? 'Not set',
              onTap: () => context.push('/setup'),
            ),
          ),
          lockTypeAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (type) {
              if (type == LockType.pin) {
                return _SettingsTile(
                  icon: Icons.pin_outlined,
                  title: 'Change PIN',
                  subtitle: 'Update your unlock PIN',
                  onTap: () => context.push('/setup/pin'),
                );
              } else if (type == LockType.pattern) {
                return _SettingsTile(
                  icon: Icons.pattern_outlined,
                  title: 'Change Pattern',
                  subtitle: 'Update your unlock pattern',
                  onTap: () => context.push('/setup/pattern'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          _SectionHeader(label: 'PERMISSIONS'),
          _PermissionTile(
            icon: Icons.bar_chart_rounded,
            title: 'Usage Access',
            subtitle: 'Required to detect locked app launches',
            granted: perms.hasUsageStats,
            onTap: () => ref.read(permissionsProvider.notifier).requestUsageStats(),
          ),
          _PermissionTile(
            icon: Icons.layers_outlined,
            title: 'Draw Over Apps',
            subtitle: 'Required to show lock screen overlay',
            granted: perms.hasOverlay,
            onTap: () => ref.read(permissionsProvider.notifier).requestOverlay(),
          ),
          _SectionHeader(label: 'ABOUT'),
          _SettingsTile(
            icon: Icons.shield_rounded,
            title: 'CMK Security',
            subtitle: 'Version 1.0.0',
            onTap: null,
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Privacy Policy',
            subtitle: 'No data is shared with third parties',
            onTap: null,
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: OutlinedButton.icon(
              onPressed: () => _confirmReset(context, ref),
              icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.error),
              label: const Text('Reset All Data', style: TextStyle(color: AppTheme.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.error),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: const Text('Reset All Data?', style: TextStyle(color: AppTheme.onBackground)),
        content: const Text(
          'This will delete your PIN/pattern, unlock all apps, and clear the file vault index. Encrypted files will remain but become inaccessible.',
          style: TextStyle(color: Color(0xFF888899)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(storageServiceProvider).clearAll();
      if (context.mounted) context.go('/splash');
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF555577),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primary.withAlpha(30),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 22),
      ),
      title: Text(title, style: const TextStyle(color: AppTheme.onBackground, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF888899), fontSize: 12)),
      trailing: onTap != null
          ? const Icon(Icons.arrow_forward_ios, color: Color(0xFF444466), size: 14)
          : null,
      onTap: onTap,
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;
  final VoidCallback onTap;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: granted
              ? AppTheme.success.withAlpha(30)
              : AppTheme.warning.withAlpha(30),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: granted ? AppTheme.success : AppTheme.warning,
          size: 22,
        ),
      ),
      title: Text(title, style: const TextStyle(color: AppTheme.onBackground, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF888899), fontSize: 12)),
      trailing: granted
          ? const Icon(Icons.check_circle_rounded, color: AppTheme.success)
          : TextButton(onPressed: onTap, child: const Text('Grant')),
    );
  }
}
