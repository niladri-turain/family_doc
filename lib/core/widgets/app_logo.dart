import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../theme/app_text_styles.dart';

/// Shield mark + "Kosh" word mark.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 36, this.showName = true});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(size * 0.3),
          ),
          child: Icon(
            Icons.verified_user_outlined,
            color: AppColors.white,
            size: size * 0.56,
          ),
        ),
        if (showName) ...[
          const SizedBox(width: 10),
          Text(
            AppStrings.appName,
            style: AppTextStyles.title.copyWith(fontSize: size * 0.56),
          ),
        ],
      ],
    );
  }
}
