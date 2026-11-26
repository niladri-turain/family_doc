import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/category_icon_box.dart';
import '../../../../core/widgets/skeleton_line.dart';

/// A tilted white "document" card used in the welcome illustration.
class FloatingDocCard extends StatelessWidget {
  const FloatingDocCard({
    super.key,
    required this.icon,
    required this.color,
    required this.width,
    required this.height,
    required this.angleDegrees,
    this.horizontal = false,
    this.lineWidths = const [110, 74],
  });

  final IconData icon;
  final CategoryColor color;
  final double width;
  final double height;
  final double angleDegrees;

  /// true = icon left of the lines, false = icon above the lines.
  final bool horizontal;
  final List<double> lineWidths;

  @override
  Widget build(BuildContext context) {
    final lines = [
      SkeletonLine(width: lineWidths[0]),
      const SizedBox(height: 8),
      SkeletonLine(width: lineWidths[1], light: true),
    ];

    return Transform.rotate(
      angle: angleDegrees * math.pi / 180,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 32,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: horizontal
            ? Row(
                children: [
                  CategoryIconBox(icon: icon, color: color, size: 34),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: lines,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryIconBox(icon: icon, color: color, size: 34),
                  const SizedBox(height: 12),
                  ...lines,
                ],
              ),
      ),
    );
  }
}
