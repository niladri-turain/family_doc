import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../documents/presentation/providers/document_provider.dart';
import '../../family/data/models/family_member.dart';
import '../../family/presentation/providers/family_provider.dart';
import '../../family/presentation/widgets/member_avatar.dart';

/// Member list with a delete button on each row.
/// Delete → confirm popup → DELETE /api/v1/family-members/{id}.
class DeleteMembersScreen extends StatefulWidget {
  const DeleteMembersScreen({super.key});

  @override
  State<DeleteMembersScreen> createState() => _DeleteMembersScreenState();
}

class _DeleteMembersScreenState extends State<DeleteMembersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<FamilyProvider>().fetchMembers(),
    );
  }

  Future<void> _delete(FamilyMember member) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Delete ${member.fullName}?',
      message: member.isSelf
          ? 'This removes your own profile (Self) and its details. '
                "This can't be undone."
          : "Their details will be removed from your family. This can't be undone.",
      confirmLabel: 'Delete',
    );
    if (!ok || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final documents = context.read<DocumentProvider>();
    try {
      await context.read<FamilyProvider>().deleteMember(member);
      await documents.removeForMember(member.id);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>();
    final members = family.members;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.lg,
                AppSizes.screenPadding,
                0,
              ),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delete member',
                          style: AppTextStyles.title.copyWith(fontSize: 18),
                        ),
                        Text(
                          'Tap the bin to remove someone',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: family.isLoading && members.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : members.isEmpty
                  ? Center(
                      child: Text(
                        'No members to delete',
                        style: AppTextStyles.body,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.screenPadding,
                        AppSizes.xl,
                        AppSizes.screenPadding,
                        AppSizes.xl,
                      ),
                      itemCount: members.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _row(
                        members[i],
                        AppColors.memberPalette[i %
                            AppColors.memberPalette.length],
                        deleting: family.deletingId == members[i].id,
                        busy: family.deletingId != null,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    FamilyMember m,
    CategoryColor color, {
    required bool deleting,
    required bool busy,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          MemberAvatar(
            initials: m.initials,
            color: color,
            photoUrl: m.photoUrl,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 3),
                Text(m.relation.label, style: AppTextStyles.small),
              ],
            ),
          ),
          SizedBox(
            width: 44,
            height: 44,
            child: deleting
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.error,
                    ),
                  )
                : IconButton(
                    tooltip: 'Delete ${m.fullName}',
                    onPressed: busy ? null : () => _delete(m),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.errorSoft,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
