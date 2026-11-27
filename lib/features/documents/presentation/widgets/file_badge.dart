import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Small tile with the file type: red for PDF, teal for photos,
/// indigo for anything else.
class FileBadge extends StatelessWidget {
  const FileBadge({super.key, required this.extension, this.size = 46});

  final String extension;
  final double size;

  static const _images = {'jpg', 'jpeg', 'png', 'heic', 'heif', 'webp'};

  @override
  Widget build(BuildContext context) {
    final ext = extension.toLowerCase();
    final color = ext == 'pdf'
        ? const CategoryColor(AppColors.error, AppColors.errorSoft)
        : _images.contains(ext)
        ? AppColors.assets
        : const CategoryColor(AppColors.primary, AppColors.primarySoft);
    final label = ext.isEmpty
        ? 'FILE'
        : (ext == 'jpeg' ? 'JPG' : ext.toUpperCase());
    return Container(
      width: size,
      height: size * 1.15,
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.only(bottom: size * 0.16),
      decoration: BoxDecoration(
        color: color.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.length > 4 ? label.substring(0, 4) : label,
        style: TextStyle(
          fontSize: size * 0.22,
          fontWeight: FontWeight.w800,
          color: color.foreground,
        ),
      ),
    );
  }
}
