import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockedApps = ref.watch(lockedAppsProvider);
    final lockedFiles = ref.watch(lockedFilesProvider);
    final perms = ref.watch(permissionsProvider);

    final appsCount = lockedApps.valueOrNull?.length ?? 0;
    final filesCount = lockedFiles.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.accent],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CMK Security',
                              style: TextStyle(
                                color: AppTheme.onBackground,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Your privacy dashboard',
                              style: TextStyle(color: Color(0xFF888899), fontSize: 12),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => context.push('/settings'),
                          icon: const Icon(Icons.settings_outlined, color: AppTheme.onSurface),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    if (!perms.allGranted) _PermissionsWarningCard(perms: perms),
                    if (!perms.allGranted) const SizedBox(height: 20),
                    // Stats row
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Locked Apps',
                            value: '$appsCount',
                            icon: Icons.apps_rounded,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Locked Files',
                            value: '$filesCount',
                            icon: Icons.lock_rounded,
                            color: AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'FEATURES',
                      style: TextStyle(
                        color: Color(0xFF555577),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _FeatureCard(
                    icon: Icons.lock_outline_rounded,
                    title: 'App Locker',
                    subtitle: 'Lock & hide apps with authentication',
                    badge: appsCount > 0 ? '$appsCount locked' : null,
                    gradient: const [Color(0xFF6C63FF), Color(0xFF8B78FF)],
                    onTap: () => context.push('/app-locker'),
                  ),
                  const SizedBox(height: 12),
                  _FeatureCard(
                    icon: Icons.lock_rounded,
                    title: 'File Vault',
                    subtitle: 'Encrypt & hide sensitive files',
                    badge: filesCount > 0 ? '$filesCount files' : null,
                    gradient: const [Color(0xFF00B4D8), Color(0xFF0077B6)],
                    onTap: () => context.push('/file-locker'),
                  ),
                  const SizedBox(height: 12),
                  _FeatureCard(
                    icon: Icons.inventory_2_rounded,
                    title: 'Vault',
                    subtitle: 'Access your hidden apps in one place',
                    gradient: const [Color(0xFF2ED573), Color(0xFF1E9E52)],
                    onTap: () => context.push('/vault'),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionsWarningCard extends StatelessWidget {
  final PermissionsState perms;

  const _PermissionsWarningCard({required this.perms});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/permissions'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.warning.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.warning.withAlpha(80)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Missing permissions — app lock may not work fully.',
                style: TextStyle(color: AppTheme.warning, fontSize: 13),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppTheme.warning, size: 14),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.onBackground,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Color(0xFF888899), fontSize: 12)),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppTheme.onBackground,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(40),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF888899), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Color(0xFF444466), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
