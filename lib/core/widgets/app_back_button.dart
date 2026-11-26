import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// 44×44 outlined square back button used at the top of inner screens.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed ?? () => Navigator.maybePop(context),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Icon(Icons.chevron_left_rounded, size: 26),
      ),
    );
  }
}
