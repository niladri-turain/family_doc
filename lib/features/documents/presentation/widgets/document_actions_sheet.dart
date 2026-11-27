import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/saved_document.dart';
import '../document_format.dart';
import 'file_badge.dart';

enum DocumentAction { open, rename, expiry, removeExpiry, share, delete }

/// Open / Rename / Expiry date / Share / Delete for one saved document
/// (⋮ on the row or a long press).
Future<DocumentAction?> showDocumentActionsSheet(
  BuildContext context,
  SavedDocument document,
) {
  Widget item(
    BuildContext context,
    DocumentAction action,
    IconData icon,
    String label, {
    bool danger = false,
  }) => ListTile(
    leading: Icon(icon, color: danger ? AppColors.error : AppColors.primary),
    title: Text(
      label,
      style: AppTextStyles.cardTitle.copyWith(
        color: danger ? AppColors.error : null,
      ),
    ),
    onTap: () => Navigator.pop(context, action),
  );

  return showModalBottomSheet<DocumentAction>(
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
              leading: FileBadge(extension: document.extension, size: 36),
              title: Text(
                document.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle,
              ),
              subtitle: Text(
                document.displayFileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.small,
              ),
            ),
            const Divider(color: AppColors.border, height: 16),
            item(
              context,
              DocumentAction.open,
              Icons.visibility_outlined,
              'Open',
            ),
            item(
              context,
              DocumentAction.rename,
              Icons.drive_file_rename_outline_rounded,
              'Rename',
            ),
            item(
              context,
              DocumentAction.expiry,
              Icons.event_outlined,
              document.expiryDate == null
                  ? 'Add expiry date'
                  : 'Change expiry date (${formatDate(document.expiryDate!)})',
            ),
            if (document.expiryDate != null)
              item(
                context,
                DocumentAction.removeExpiry,
                Icons.event_busy_outlined,
                'Remove expiry date',
              ),
            item(context, DocumentAction.share, Icons.share_outlined, 'Share'),
            item(
              context,
              DocumentAction.delete,
              Icons.delete_outline_rounded,
              'Delete',
              danger: true,
            ),
          ],
        ),
      ),
    ),
  );
}
