import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/document_type.dart';

/// Illustration, "No … documents yet" and the category's document types
/// as chips (tapping one selects that type).
class DocumentsEmptyState extends StatelessWidget {
  const DocumentsEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.types = const [],
    this.onTypeTap,
  });

  final String title;
  final String message;
  final List<DocumentType> types;
  final ValueChanged<DocumentType>? onTypeTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _Illustration(),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.title.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        if (types.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in types)
                Material(
                  color: AppColors.primarySoft,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: onTypeTap == null ? null : () => onTypeTap!(t),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        t.name,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Soft circle with two stacked pages and a "+" badge.
class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    Widget page({double angle = 0, bool front = false}) => Transform.rotate(
      angle: angle,
      child: Container(
        width: 62,
        height: 78,
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 0),
        decoration: BoxDecoration(
          color: front ? AppColors.white : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primarySofter),
          boxShadow: front
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: front
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(36, AppColors.primary),
                  const SizedBox(height: 7),
                  _bar(28, AppColors.primarySofter),
                  const SizedBox(height: 6),
                  _bar(22, AppColors.primarySofter),
                ],
              )
            : null,
      ),
    );

    return Container(
      width: 140,
      height: 140,
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(left: 30, top: 34, child: page(angle: -0.18)),
          Positioned(left: 46, top: 28, child: page(front: true)),
          Positioned(
            right: 22,
            bottom: 26,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 3),
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 18,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _bar(double width, Color color) => Container(
    width: width,
    height: 5,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(3),
    ),
  );
}
