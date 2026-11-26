import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Rounded square with a category icon on its soft tint
/// (used on dashboard tiles, document lists, the welcome illustration…).
class CategoryIconBox extends StatelessWidget {
  const CategoryIconBox({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
  });

  final IconData icon;
  final CategoryColor color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.background,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: color.foreground, size: size * 0.5),
    );
  }
}
