import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Pill used to pick a relation (Self, Father, Mother…).
class RelationChip extends StatelessWidget {
  const RelationChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: AppColors.white,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? AppColors.white : AppColors.textLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
