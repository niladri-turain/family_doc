import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/category_icon_box.dart';
import '../../../categories/data/models/document_category.dart';
import '../../../categories/presentation/category_style.dart';

enum CategoryAction { edit, delete }

/// Edit / Delete sheet for one of the user's own categories.
Future<CategoryAction?> showCategoryActionsSheet(
  BuildContext context,
  DocumentCategory category,
) {
  final style = CategoryStyle.of(category.name);
  return showModalBottomSheet<CategoryAction>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CategoryIconBox(icon: style.icon, color: style.color),
              title: Text(category.name, style: AppTextStyles.cardTitle),
              subtitle: Text(
                category.description.isEmpty
                    ? 'Your category'
                    : category.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.small,
              ),
            ),
            const Divider(color: AppColors.border, height: 16),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
              ),
              title: Text('Edit category', style: AppTextStyles.cardTitle),
              onTap: () => Navigator.pop(context, CategoryAction.edit),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
              title: Text(
                'Delete category',
                style: AppTextStyles.cardTitle.copyWith(color: AppColors.error),
              ),
              onTap: () => Navigator.pop(context, CategoryAction.delete),
            ),
          ],
        ),
      ),
    ),
  );
}
