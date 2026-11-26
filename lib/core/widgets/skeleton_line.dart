import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Grey rounded bar used as placeholder text in illustrations and loaders.
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({
    super.key,
    required this.width,
    this.height = 8,
    this.light = false,
  });

  final double width;
  final double height;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: light ? AppColors.skeletonLight : AppColors.skeleton,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
