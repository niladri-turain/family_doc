import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

enum StepStatus { pending, running, done }

/// One row in the "Verifying your number" checklist.
class VerifyStepRow extends StatelessWidget {
  const VerifyStepRow({
    super.key,
    required this.label,
    required this.status,
    this.trailing,
    this.showDivider = true,
  });

  final String label;
  final StepStatus status;
  final String? trailing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    Widget leading;
    switch (status) {
      case StepStatus.done:
        leading = Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 16,
            color: AppColors.white,
          ),
        );
      case StepStatus.running:
        leading = const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.primary,
            backgroundColor: AppColors.primarySofter,
          ),
        );
      case StepStatus.pending:
        leading = Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 2),
          ),
        );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.skeletonLight))
            : null,
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(
                fontSize: 14,
                fontWeight: status == StepStatus.running
                    ? FontWeight.w700
                    : FontWeight.w600,
                color: switch (status) {
                  StepStatus.running => AppColors.primary,
                  StepStatus.done => AppColors.textPrimary,
                  StepStatus.pending => AppColors.textSecondary,
                },
              ),
            ),
          ),
          if (trailing != null) Text(trailing!, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
