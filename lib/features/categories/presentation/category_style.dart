import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Icon + color for a category, picked by its name from the API.
/// Unknown names get a folder icon in the brand color.
class CategoryStyle {
  const CategoryStyle(this.icon, this.color);

  final IconData icon;
  final CategoryColor color;

  static CategoryStyle of(String name) {
    switch (name.trim().toLowerCase()) {
      case 'education':
        return const CategoryStyle(
          Icons.menu_book_outlined,
          AppColors.education,
        );
      case 'government':
        return const CategoryStyle(
          Icons.account_balance_outlined,
          AppColors.government,
        );
      case 'assets':
        return const CategoryStyle(Icons.home_outlined, AppColors.assets);
      case 'health':
        return const CategoryStyle(
          Icons.favorite_border_rounded,
          AppColors.health,
        );
      default:
        return const CategoryStyle(
          Icons.folder_outlined,
          CategoryColor(AppColors.primary, AppColors.primarySoft),
        );
    }
  }
}
