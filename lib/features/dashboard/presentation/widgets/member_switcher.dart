import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../family/data/models/family_member.dart';
import '../../../family/presentation/widgets/member_avatar.dart';

/// Pill showing the selected member; tap to pick another one.
class MemberSwitcher extends StatelessWidget {
  const MemberSwitcher({super.key, required this.member, required this.onTap});

  final FamilyMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const StadiumBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MemberAvatar(
                initials: member.initials,
                color: const CategoryColor(
                  AppColors.primary,
                  AppColors.primarySoft,
                ),
                photoUrl: member.photoUrl,
                size: 36,
                circle: true,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      member.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle,
                    ),
                    Text(
                      member.relation.label,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet listing all members; returns the one tapped.
Future<FamilyMember?> showMemberPicker(
  BuildContext context, {
  required List<FamilyMember> members,
  required int? selectedId,
}) {
  return showModalBottomSheet<FamilyMember>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(8, 20, 8, 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Show documents of',
                style: AppTextStyles.title.copyWith(fontSize: 18),
              ),
            ),
            for (final (i, m) in members.indexed)
              ListTile(
                leading: MemberAvatar(
                  initials: m.initials,
                  color: AppColors
                      .memberPalette[i % AppColors.memberPalette.length],
                  photoUrl: m.photoUrl,
                  size: 40,
                  circle: true,
                ),
                title: Text(m.fullName, style: AppTextStyles.cardTitle),
                subtitle: Text(m.relation.label, style: AppTextStyles.small),
                trailing: m.id == selectedId
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, m),
              ),
          ],
        ),
      ),
    ),
  );
}
