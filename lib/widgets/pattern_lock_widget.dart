import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class PatternLockWidget extends StatefulWidget {
  final int gridSize;
  final void Function(List<int> pattern) onComplete;
  final double dotSize;
  final double selectedDotSize;

  const PatternLockWidget({
    super.key,
    this.gridSize = 3,
    required this.onComplete,
    this.dotSize = 14,
    this.selectedDotSize = 20,
  });

  @override
  State<PatternLockWidget> createState() => PatternLockWidgetState();
}

class PatternLockWidgetState extends State<PatternLockWidget> {
  final List<int> _pattern = [];
  final List<Offset> _dotPositions = [];
  Offset? _currentPos;
  bool _error = false;
  Size _size = Size.zero;

  void reset() => setState(() {
    _pattern.clear();
    _currentPos = null;
    _error = false;
  });

  void showError() {
    setState(() => _error = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) reset();
    });
  }

  Offset _dotCenter(int index) {
    final col = index % widget.gridSize;
    final row = index ~/ widget.gridSize;
    final cellW = _size.width / widget.gridSize;
    final cellH = _size.height / widget.gridSize;
    return Offset(cellW * col + cellW / 2, cellH * row + cellH / 2);
  }

  int? _hitTest(Offset pos) {
    for (int i = 0; i < widget.gridSize * widget.gridSize; i++) {
      if (_dotPositions.isEmpty) break;
      final center = _dotPositions[i];
      if ((pos - center).distance < 30) return i;
    }
    return null;
  }

  void _onPanStart(DragStartDetails details) {
    reset();
    _onPanUpdate(DragUpdateDetails(
      globalPosition: details.globalPosition,
      localPosition: details.localPosition,
      delta: Offset.zero,
    ));
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() => _currentPos = details.localPosition);
    final hit = _hitTest(details.localPosition);
    if (hit != null && !_pattern.contains(hit)) {
      setState(() => _pattern.add(hit));
    }
  }

  void _onPanEnd(DragEndDetails _) {
    setState(() => _currentPos = null);
    if (_pattern.length >= 4) {
      widget.onComplete(List.from(_pattern));
    } else if (_pattern.isNotEmpty) {
      showError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final side = constraints.maxWidth < constraints.maxHeight
          ? constraints.maxWidth
          : constraints.maxHeight;
      _size = Size(side, side);

      _dotPositions.clear();
      for (int i = 0; i < widget.gridSize * widget.gridSize; i++) {
        _dotPositions.add(_dotCenter(i));
      }

      return GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: SizedBox(
          width: side,
          height: side,
          child: CustomPaint(
            painter: _PatternPainter(
              pattern: _pattern,
              dotPositions: List.from(_dotPositions),
              currentPos: _currentPos,
              error: _error,
              dotSize: widget.dotSize,
              selectedDotSize: widget.selectedDotSize,
            ),
          ),
        ),
      );
    });
  }
}

class _PatternPainter extends CustomPainter {
  final List<int> pattern;
  final List<Offset> dotPositions;
  final Offset? currentPos;
  final bool error;
  final double dotSize;
  final double selectedDotSize;

  _PatternPainter({
    required this.pattern,
    required this.dotPositions,
    this.currentPos,
    required this.error,
    required this.dotSize,
    required this.selectedDotSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final color = error ? AppTheme.error : AppTheme.primary;
    final linePaint = Paint()
      ..color = color.withAlpha(160)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw connecting lines
    for (int i = 0; i < pattern.length - 1; i++) {
      canvas.drawLine(dotPositions[pattern[i]], dotPositions[pattern[i + 1]], linePaint);
    }
    if (pattern.isNotEmpty && currentPos != null) {
      canvas.drawLine(dotPositions[pattern.last], currentPos!, linePaint);
    }

    // Draw dots
    for (int i = 0; i < dotPositions.length; i++) {
      final isSelected = pattern.contains(i);
      final center = dotPositions[i];
      final radius = isSelected ? selectedDotSize / 2 : dotSize / 2;

      // Outer ring
      final ringPaint = Paint()
        ..color = isSelected ? color : const Color(0xFF444466)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius + 4, ringPaint);

      // Fill
      final fillPaint = Paint()
        ..color = isSelected ? color : const Color(0xFF333355)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, fillPaint);
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) =>
      old.pattern != pattern ||
      old.currentPos != currentPos ||
      old.error != error;
}
