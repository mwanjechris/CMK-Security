import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lock_type.dart';
import '../../providers/providers.dart';
import '../../widgets/pattern_lock_widget.dart';
import '../../widgets/pin_pad_widget.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final String? redirectTo;

  const AuthScreen({super.key, this.redirectTo});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final GlobalKey<PinPadWidgetState> _pinKey = GlobalKey<PinPadWidgetState>();
  final GlobalKey<PatternLockWidgetState> _patternKey = GlobalKey();
  bool _authenticating = false;

  Future<void> _handlePin(String pin) async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    final auth = ref.read(authServiceProvider);
    final ok = await auth.verifyPin(pin);
    if (!mounted) return;
    setState(() => _authenticating = false);
    if (ok) {
      _onSuccess();
    } else {
      _pinKey.currentState?.showError();
    }
  }

  Future<void> _handlePattern(List<int> pattern) async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    final auth = ref.read(authServiceProvider);
    final ok = await auth.verifyPattern(pattern);
    if (!mounted) return;
    setState(() => _authenticating = false);
    if (ok) {
      _onSuccess();
    } else {
      _patternKey.currentState?.showError();
    }
  }

  Future<void> _handleBiometric() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    final auth = ref.read(authServiceProvider);
    final ok = await auth.authenticateWithBiometric();
    if (!mounted) return;
    setState(() => _authenticating = false);
    if (ok) _onSuccess();
  }

  void _onSuccess() {
    final target = widget.redirectTo ?? '/home';
    context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    final lockTypeAsync = ref.watch(lockTypeProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: lockTypeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Error loading lock type')),
          data: (lockType) {
            if (lockType == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/setup'));
              return const SizedBox.shrink();
            }
            return _buildAuthUI(lockType);
          },
        ),
      ),
    );
  }

  Widget _buildAuthUI(LockType lockType) {
    return Column(
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.shield_rounded, color: AppTheme.primary, size: 56),
        const SizedBox(height: 16),
        const Text(
          'CMK Security',
          style: TextStyle(
            color: AppTheme.onBackground,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          lockType == LockType.pin
              ? 'Enter your PIN'
              : lockType == LockType.pattern
                  ? 'Draw your pattern'
                  : 'Authenticate to continue',
          style: const TextStyle(color: Color(0xFF888899), fontSize: 14),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: _buildLockWidget(lockType),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLockWidget(LockType lockType) {
    switch (lockType) {
      case LockType.pin:
        return PinPadWidget(
          key: _pinKey,
          onComplete: _handlePin,
          showBiometric: false,
          title: '',
        );

      case LockType.pattern:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 280,
              height: 280,
              child: PatternLockWidget(
                key: _patternKey,
                onComplete: _handlePattern,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Connect 4+ dots to unlock',
              style: TextStyle(color: Color(0xFF666688), fontSize: 13),
            ),
          ],
        );

      case LockType.biometric:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _handleBiometric,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primary, width: 2),
                ),
                child: const Icon(Icons.fingerprint, color: AppTheme.primary, size: 60),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Touch the fingerprint sensor',
              style: TextStyle(color: Color(0xFF888899), fontSize: 14),
            ),
            const SizedBox(height: 32),
            if (_authenticating)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _handleBiometric,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Authenticate'),
              ),
          ],
        );
    }
  }
}

