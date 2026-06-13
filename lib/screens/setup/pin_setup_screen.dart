import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lock_type.dart';
import '../../providers/providers.dart';
import '../../widgets/pin_pad_widget.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String? _firstPin;
  bool _confirming = false;
  final GlobalKey<PinPadWidgetState> _pinKey = GlobalKey<PinPadWidgetState>();

  Future<void> _onPin(String pin) async {
    if (!_confirming) {
      setState(() {
        _firstPin = pin;
        _confirming = true;
      });
    } else {
      if (pin == _firstPin) {
        final auth = ref.read(authServiceProvider);
        await auth.setPin(pin);
        await ref.read(lockTypeProvider.notifier).setLockType(LockType.pin);
        final storage = ref.read(storageServiceProvider);
        await storage.markSetupComplete();
        if (mounted) context.go('/permissions');
      } else {
        _pinKey.currentState?.showError();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("PINs don't match. Try again.")),
          );
          setState(() {
            _confirming = false;
            _firstPin = null;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Set PIN'),
        backgroundColor: AppTheme.background,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: PinPadWidget(
            key: _pinKey,
            pinLength: 4,
            onComplete: _onPin,
            title: _confirming ? 'Confirm PIN' : 'Create PIN',
            subtitle: _confirming
                ? 'Re-enter your PIN to confirm'
                : 'Choose a 4-digit PIN',
          ),
        ),
      ),
    );
  }
}
