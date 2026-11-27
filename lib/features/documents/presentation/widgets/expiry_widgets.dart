import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/saved_document.dart';
import '../document_format.dart';

/// Date picker for a document's last valid day.
Future<DateTime?> pickExpiryDate(BuildContext context, {DateTime? initial}) {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initial ?? DateTime(now.year + 1, now.month, now.day),
    firstDate: DateTime(now.year - 30),
    lastDate: DateTime(now.year + 50),
    helpText: 'Expiry date',
  );
}

/// "⏱ Expires in 12 days": red once expired, orange within a month,
/// grey later. Nothing when the document has no expiry date.
class ExpiryLabel extends StatelessWidget {
  const ExpiryLabel({super.key, required this.document, this.now});

  final SavedDocument document;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final expiry = document.expiryDate;
    final days = document.daysToExpiry(now);
    if (expiry == null || days == null) return const SizedBox.shrink();
    final status = expiryStatusOf(days);
    final (color, background) = switch (status) {
      ExpiryStatus.expired => (AppColors.error, AppColors.errorSoft),
      ExpiryStatus.soon => (AppColors.warning, AppColors.warningSoft),
      ExpiryStatus.later => (AppColors.textSecondary, AppColors.surface),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == ExpiryStatus.expired
                ? Icons.error_outline_rounded
                : Icons.schedule_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              expiryLabel(expiry, days),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
