import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/saved_document.dart';
import '../document_format.dart';
import 'document_thumbnail.dart';

/// White row: file badge, name, type chip, "1.2 MB · Today" and a share
/// button. Tap opens the file, ⋮ shows more actions, a long press starts
/// selecting. While [selecting], the buttons give way to a check circle.
class DocumentTile extends StatelessWidget {
  const DocumentTile({
    super.key,
    required this.document,
    required this.onOpen,
    required this.onShare,
    this.onMore,
    this.onLongPress,
    this.selecting = false,
    this.selected = false,
  });

  final SavedDocument document;

  /// Tap: opens the file, or toggles it while [selecting].
  final VoidCallback onOpen;
  final VoidCallback? onLongPress;
  final bool selecting;
  final bool selected;

  /// Gets the share button's position (for the iPad popover).
  final ValueChanged<Rect?> onShare;

  /// Rename / Delete… sheet (⋮ button).
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final type = document.typeName;
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              DocumentThumbnail(document: document),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle,
                    ),
                    if (type != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          type,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${formatFileSize(document.size)} · '
                      '${formatSavedDate(document.createdAt)}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              if (selecting)
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 26,
                    semanticLabel: selected
                        ? '${document.name} selected'
                        : '${document.name} not selected',
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                )
              else ...[
                Builder(
                  builder: (buttonContext) => IconButton(
                    tooltip: 'Share ${document.name}',
                    onPressed: () {
                      final box =
                          buttonContext.findRenderObject() as RenderBox?;
                      onShare(
                        box == null
                            ? null
                            : box.localToGlobal(Offset.zero) & box.size,
                      );
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      fixedSize: const Size(44, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.share_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (onMore != null)
                  IconButton(
                    tooltip: 'More for ${document.name}',
                    onPressed: onMore,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
