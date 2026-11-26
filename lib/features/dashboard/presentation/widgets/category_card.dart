import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/category_icon_box.dart';
import '../../../categories/data/models/document_category.dart';
import '../../../categories/presentation/category_style.dart';

/// Dashboard tile: icon, document count, category name and a subtitle.
class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.category, this.onTap});

  final DocumentCategory category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(category.name);
    final count = category.documentCount;
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryIconBox(icon: style.icon, color: style.color),
                  const Spacer(),
                  Text(
                    '$count',
                    style: AppTextStyles.title.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: count == 0
                          ? AppColors.disabledText.withValues(alpha: 0.7)
                          : style.color.foreground,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                count == 0
                    ? 'No documents'
                    : '$count ${count == 1 ? 'document' : 'documents'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
