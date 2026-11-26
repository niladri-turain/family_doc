import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Indigo card: total documents, category count and a progress bar
/// (share of categories that have at least one document).
class TotalDocumentsCard extends StatelessWidget {
  const TotalDocumentsCard({
    super.key,
    required this.total,
    required this.categoryCount,
    required this.filledCategories,
  });

  final int total;
  final int categoryCount;
  final int filledCategories;

  @override
  Widget build(BuildContext context) {
    final progress = categoryCount == 0
        ? 0.0
        : filledCategories / categoryCount;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: AppColors.primary,
        child: Stack(
          children: [
            Positioned(right: -50, top: -40, child: _circle(170)),
            Positioned(right: 10, bottom: -90, child: _circle(150)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total documents',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$total',
                        style: AppTextStyles.display.copyWith(
                          fontSize: 40,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'in $categoryCount '
                          '${categoryCount == 1 ? 'category' : 'categories'}',
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      color: AppColors.white,
                      backgroundColor: AppColors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    total == 0
                        ? 'Nothing uploaded yet'
                        : '$filledCategories of $categoryCount categories have documents',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.white.withValues(alpha: 0.07),
    ),
  );
}
