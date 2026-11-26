import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

enum PhotoAction { camera, gallery, remove }

/// Bottom sheet: Take photo / Choose from gallery / Remove photo.
Future<PhotoAction?> showPhotoSourceSheet(
  BuildContext context, {
  required bool hasPhoto,
}) {
  return showModalBottomSheet<PhotoAction>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Profile photo',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              'Photos over 2 MB are optimised automatically.',
              style: AppTextStyles.small,
            ),
            const SizedBox(height: 12),
            _SheetOption(
              icon: Icons.photo_camera_outlined,
              label: 'Take photo',
              action: PhotoAction.camera,
            ),
            _SheetOption(
              icon: Icons.photo_library_outlined,
              label: 'Choose from gallery',
              action: PhotoAction.gallery,
            ),
            if (hasPhoto)
              const _SheetOption(
                icon: Icons.delete_outline_rounded,
                label: 'Remove photo',
                action: PhotoAction.remove,
                danger: true,
              ),
          ],
        ),
      ),
    ),
  );
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.action,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final PhotoAction action;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.primary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: danger ? AppColors.errorSoft : AppColors.primarySoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: AppTextStyles.cardTitle.copyWith(
          color: danger ? AppColors.error : null,
        ),
      ),
      onTap: () => Navigator.pop(context, action),
    );
  }
}
