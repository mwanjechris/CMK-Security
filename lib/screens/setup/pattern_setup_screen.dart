import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lock_type.dart';
import '../../providers/providers.dart';
import '../../widgets/pattern_lock_widget.dart';

class PatternSetupScreen extends ConsumerStatefulWidget {
  const PatternSetupScreen({super.key});

  @override
  ConsumerState<PatternSetupScreen> createState() => _PatternSetupScreenState();
}

class _PatternSetupScreenState extends ConsumerState<PatternSetupScreen> {
  List<int>? _firstPattern;
  bool _confirming = false;
  final GlobalKey<PatternLockWidgetState> _patternKey = GlobalKey();

  Future<void> _onPattern(List<int> pattern) async {
    if (!_confirming) {
      setState(() {
        _firstPattern = pattern;
        _confirming = true;
      });
      _patternKey.currentState?.reset();
    } else {
      if (_listsEqual(pattern, _firstPattern!)) {
        final auth = ref.read(authServiceProvider);
        await auth.setPattern(pattern);
        await ref.read(lockTypeProvider.notifier).setLockType(LockType.pattern);
        final storage = ref.read(storageServiceProvider);
        await storage.markSetupComplete();
        if (mounted) context.go('/permissions');
      } else {
        _patternKey.currentState?.showError();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Patterns don't match. Try again.")),
          );
          setState(() {
            _confirming = false;
            _firstPattern = null;
          });
        }
      }
    }
  }

  bool _listsEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Set Pattern'),
        backgroundColor: AppTheme.background,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              _confirming ? 'Confirm Pattern' : 'Create Pattern',
              style: const TextStyle(
                color: AppTheme.onBackground,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _confirming
                  ? 'Draw the same pattern again'
                  : 'Connect at least 4 dots',
              style: const TextStyle(color: Color(0xFF888899), fontSize: 14),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: PatternLockWidget(
                    key: _patternKey,
                    onComplete: _onPattern,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
