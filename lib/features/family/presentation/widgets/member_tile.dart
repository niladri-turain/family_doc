import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/family_member.dart';
import 'member_avatar.dart';

/// White card in the My Family list: avatar, name, "Relation · N documents".
class MemberTile extends StatelessWidget {
  const MemberTile({
    super.key,
    required this.member,
    required this.color,
    this.onTap,
  });

  final FamilyMember member;
  final CategoryColor color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final docs = member.documentCount;
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              MemberAvatar(
                initials: member.initials,
                color: color,
                photoUrl: member.photoUrl,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${member.relation.label} · $docs '
                      '${docs == 1 ? 'document' : 'documents'}',
                      style: AppTextStyles.small,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.disabledText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
