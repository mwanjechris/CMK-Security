import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

class PermissionsScreen extends ConsumerWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms = ref.watch(permissionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.verified_user_outlined, color: AppTheme.primary, size: 56),
              const SizedBox(height: 24),
              const Text(
                'Required\nPermissions',
                style: TextStyle(
                  color: AppTheme.onBackground,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Grant these permissions so CMK Security can protect your apps.',
                style: TextStyle(color: Color(0xFF888899), fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 40),
              _PermissionTile(
                icon: Icons.bar_chart_rounded,
                title: 'Usage Access',
                description: 'Detect when locked apps are opened',
                granted: perms.hasUsageStats,
                onGrant: () => ref.read(permissionsProvider.notifier).requestUsageStats(),
              ),
              const SizedBox(height: 12),
              _PermissionTile(
                icon: Icons.layers_outlined,
                title: 'Draw Over Apps',
                description: 'Show lock screen on top of locked apps',
                granted: perms.hasOverlay,
                onGrant: () => ref.read(permissionsProvider.notifier).requestOverlay(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: perms.allGranted
                      ? () => context.go('/home')
                      : null,
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/home'),
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(color: Color(0xFF666688)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool granted;
  final VoidCallback onGrant;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.granted,
    required this.onGrant,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: granted ? AppTheme.success.withAlpha(80) : AppTheme.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: granted
                  ? AppTheme.success.withAlpha(30)
                  : AppTheme.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: granted ? AppTheme.success : AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.onBackground,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(color: Color(0xFF888899), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          granted
              ? const Icon(Icons.check_circle_rounded, color: AppTheme.success)
              : TextButton(
                  onPressed: onGrant,
                  child: const Text('Grant'),
                ),
        ],
      ),
    );
  }
}
