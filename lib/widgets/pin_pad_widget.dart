import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class PinPadWidget extends StatefulWidget {
  final int pinLength;
  final void Function(String pin) onComplete;
  final VoidCallback? onBiometric;
  final String? title;
  final String? subtitle;
  final bool showBiometric;

  const PinPadWidget({
    super.key,
    this.pinLength = 4,
    required this.onComplete,
    this.onBiometric,
    this.title,
    this.subtitle,
    this.showBiometric = false,
  });

  @override
  State<PinPadWidget> createState() => PinPadWidgetState();
}

class PinPadWidgetState extends State<PinPadWidget> with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _error = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKey(String key) {
    if (_pin.length >= widget.pinLength) return;
    setState(() => _pin += key);
    if (_pin.length == widget.pinLength) {
      widget.onComplete(_pin);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void showError() {
    setState(() => _error = true);
    _shakeController.forward(from: 0).then((_) {
      setState(() {
        _error = false;
        _pin = '';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: const TextStyle(
              color: AppTheme.onBackground,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (widget.subtitle != null) ...[
          Text(
            widget.subtitle!,
            style: const TextStyle(color: Color(0xFF888899), fontSize: 14),
          ),
          const SizedBox(height: 32),
        ] else
          const SizedBox(height: 32),
        AnimatedBuilder(
          animation: _shakeAnim,
          builder: (context, child) {
            final offset = _error
                ? 12.0 * (0.5 - (_shakeAnim.value - 0.5).abs())
                : 0.0;
            return Transform.translate(
              offset: Offset(offset * 4, 0),
              child: child,
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.pinLength, (i) {
              final filled = i < _pin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _error
                      ? AppTheme.error
                      : filled
                          ? AppTheme.primary
                          : Colors.transparent,
                  border: Border.all(
                    color: _error
                        ? AppTheme.error
                        : filled
                            ? AppTheme.primary
                            : const Color(0xFF444466),
                    width: 2,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 40),
        // Number pad
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ]) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) => _buildKey(key)).toList(),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.showBiometric && widget.onBiometric != null)
              _buildActionKey(
                icon: Icons.fingerprint,
                onTap: widget.onBiometric!,
              )
            else
              const SizedBox(width: 80, height: 80),
            const SizedBox(width: 12),
            _buildKey('0'),
            const SizedBox(width: 12),
            _buildActionKey(
              icon: Icons.backspace_outlined,
              onTap: _onDelete,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String digit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: AppTheme.surfaceVariant,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _onKey(digit),
          child: SizedBox(
            width: 72,
            height: 72,
            child: Center(
              child: Text(
                digit,
                style: const TextStyle(
                  color: AppTheme.onBackground,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey({required IconData icon, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 72,
            height: 72,
            child: Center(
              child: Icon(icon, color: AppTheme.onSurface, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
