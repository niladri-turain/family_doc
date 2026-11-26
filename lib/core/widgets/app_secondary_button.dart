import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../theme/app_text_styles.dart';

/// Full-width white outlined button for the second action on a screen.
/// Pass `onPressed: null` to show it disabled.
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final color = enabled ? AppColors.textPrimary : AppColors.disabledText;
    return SizedBox(
      height: AppSizes.buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: enabled ? AppColors.white : AppColors.surface,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                size: 20,
                color: enabled ? AppColors.primary : AppColors.disabledText,
              ),
              const SizedBox(width: AppSizes.sm),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.button.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
