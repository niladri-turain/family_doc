import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/category_icon_box.dart';
import '../../../../core/widgets/dashed_border_box.dart';
import '../../../categories/data/models/document_category.dart';
import '../../../categories/presentation/category_style.dart';

/// Dashboard tile: icon, document count, category name and a subtitle.
/// The user's own categories get a dotted border in their color and a ⋮
/// button ([onMore], also on long press) for Edit / Delete; built-in ones
/// have a plain border and no menu.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    this.onTap,
    this.onMore,
  });

  final DocumentCategory category;
  final VoidCallback? onTap;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(category.name);
    final count = category.documentCount;
    final custom = category.isCustom && onMore != null;
    final card = Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: custom
            ? BorderSide.none
            : const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        onLongPress: custom ? onMore : null,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, custom ? 6 : 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryIconBox(icon: style.icon, color: style.color),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.only(right: custom ? 10 : 0),
                    child: Text(
                      '$count',
                      style: AppTextStyles.title.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: count == 0
                            ? AppColors.disabledText.withValues(alpha: 0.7)
                            : style.color.foreground,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                  if (custom)
                    IconButton(
                      tooltip: 'Edit or delete ${category.name}',
                      onPressed: onMore,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (!custom) return card;
    return DashedBorderBox(
      radius: 20,
      color: style.color.foreground,
      padding: EdgeInsets.zero,
      dash: 0.1,
      gap: 5,
      strokeWidth: 2,
      child: card,
    );
  }
}
