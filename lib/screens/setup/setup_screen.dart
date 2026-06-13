import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lock_type.dart';
import '../../providers/providers.dart';

class SetupScreen extends ConsumerWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 32),
              const Text(
                'Set Up\nCMK Security',
                style: TextStyle(
                  color: AppTheme.onBackground,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose how you want to protect your apps and files.',
                style: TextStyle(color: Color(0xFF888899), fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 48),
              const Text(
                'SELECT LOCK TYPE',
                style: TextStyle(
                  color: Color(0xFF555577),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              _LockTypeCard(
                type: LockType.pin,
                icon: Icons.pin_outlined,
                onTap: () => context.push('/setup/pin'),
              ),
              const SizedBox(height: 12),
              _LockTypeCard(
                type: LockType.pattern,
                icon: Icons.pattern_outlined,
                onTap: () => context.push('/setup/pattern'),
              ),
              const SizedBox(height: 12),
              _LockTypeCard(
                type: LockType.biometric,
                icon: Icons.fingerprint,
                onTap: () => _setupBiometric(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setupBiometric(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(authServiceProvider);
    final available = await auth.isBiometricAvailable();
    if (!context.mounted) return;
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric not available on this device')),
      );
      return;
    }
    await ref.read(lockTypeProvider.notifier).setLockType(LockType.biometric);
    final storage = ref.read(storageServiceProvider);
    await storage.markSetupComplete();
    if (context.mounted) context.go('/permissions');
  }
}

class _LockTypeCard extends StatelessWidget {
  final LockType type;
  final IconData icon;
  final VoidCallback onTap;

  const _LockTypeCard({required this.type, required this.icon, required this.onTap});

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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.label,
                      style: const TextStyle(
                        color: AppTheme.onBackground,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type.description,
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
