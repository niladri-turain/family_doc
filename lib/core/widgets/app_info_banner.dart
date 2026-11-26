import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_text_styles.dart';

enum BannerType { info, error }

/// Rounded card with an icon, a bold title and a message.
class AppInfoBanner extends StatelessWidget {
  const AppInfoBanner({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.type = BannerType.info,
  });

  final String title;
  final String message;
  final IconData? icon;
  final BannerType type;

  @override
  Widget build(BuildContext context) {
    final isError = type == BannerType.error;
    final textColor = isError ? AppColors.errorText : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isError ? AppColors.errorSurface : AppColors.surface,
        border: isError ? Border.all(color: AppColors.errorBorder) : null,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isError ? AppColors.errorSoft : AppColors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon ?? (isError ? Icons.error_outline : Icons.bolt_outlined),
              size: 19,
              color: isError ? AppColors.error : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.label
                        .copyWith(fontSize: 14, color: textColor)),
                const SizedBox(height: 4),
                Text(message,
                    style: AppTextStyles.small.copyWith(
                        color: isError ? textColor : AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
