import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Box with a dashed rounded border. A very short [dash] with a round cap
/// draws dots instead (e.g. `dash: 0.1, gap: 5`).
class DashedBorderBox extends StatelessWidget {
  const DashedBorderBox({
    super.key,
    required this.child,
    this.radius = 18,
    this.color = AppColors.dashedBorder,
    this.padding = const EdgeInsets.all(16),
    this.dash = 5,
    this.gap = 4,
    this.strokeWidth = 1.2,
  });

  final Widget child;
  final double radius;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double dash;
  final double gap;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedRRectPainter(
        radius: radius,
        color: color,
        dash: dash,
        gap: gap,
        strokeWidth: strokeWidth,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({
    required this.radius,
    required this.color,
    required this.dash,
    required this.gap,
    required this.strokeWidth,
  });

  final double radius;
  final Color color;
  final double dash;
  final double gap;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final inset = strokeWidth / 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - strokeWidth,
            size.height - strokeWidth,
          ),
          Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.radius != radius ||
      old.color != color ||
      old.dash != dash ||
      old.gap != gap ||
      old.strokeWidth != strokeWidth;
}
