import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../documents/presentation/providers/document_provider.dart';
import 'providers/family_provider.dart';
import 'widgets/empty_family_view.dart';
import 'widgets/member_tile.dart';

/// My Family: fetches the member list from the API when it opens.
/// Empty → "Add myself" (family member disabled until Self exists).
/// Full  → list with search, + button and bottom bar.
class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    final family = context.read<FamilyProvider>();
    await family.fetchMembers();
    // Token expired / invalid → back to login.
    if (mounted && (family.error?.isUnauthorized ?? false)) {
      await context.read<AuthProvider>().logout();
      family.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your session has expired. Please log in again.'),
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.welcome,
        (_) => false,
      );
    }
  }

  void _addMember({required bool self}) =>
      Navigator.pushNamed(context, AppRoutes.addMember, arguments: self);

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>();

    if (!family.hasLoaded) {
      if (family.error != null && !family.isLoading) {
        return _buildError(family.error!.message);
      }
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return family.members.isEmpty ? _buildEmpty(family) : _buildList(family);
  }

  // ───────────── Error (first load failed) ─────────────
  Widget _buildError(String message) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                "Couldn't load your family",
                style: AppTextStyles.title.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 24),
              AppPrimaryButton(
                label: 'Try again',
                leadingIcon: Icons.refresh_rounded,
                onPressed: _fetch,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────── Empty state ─────────────
  Widget _buildEmpty(FamilyProvider family) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'My Family',
                          style: AppTextStyles.title.copyWith(fontSize: 24),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Step 1 of 2',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const EmptyFamilyView(),
              const Spacer(flex: 2),
              AppPrimaryButton(
                label: 'Add myself',
                leadingIcon: Icons.person_outline_rounded,
                onPressed: family.hasSelf ? null : () => _addMember(self: true),
              ),
              const SizedBox(height: AppSizes.md),
              AppSecondaryButton(
                label: 'Add family member',
                leadingIcon: Icons.add_rounded,
                // Enabled only after "Self" is added.
                onPressed: family.hasSelf
                    ? () => _addMember(self: false)
                    : null,
              ),
              if (!family.hasSelf) ...[
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Add yourself first to add family members',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ───────────── Full state ─────────────
  Widget _buildList(FamilyProvider family) {
    final members = family.filteredMembers;
    final count = family.members.length;
    final saved = context.watch<DocumentProvider>();
    final docs = family.members.fold(0, (sum, m) => sum + saved.totalFor(m.id));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$count ${count == 1 ? 'member' : 'members'} · '
                          '$docs ${docs == 1 ? 'document' : 'documents'}',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'My Family',
                          style: AppTextStyles.title.copyWith(fontSize: 24),
                        ),
                      ],
                    ),
                  ),
                  _AddButton(
                    onPressed: () => _addMember(self: !family.hasSelf),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                20,
                AppSizes.screenPadding,
                0,
              ),
              child: TextField(
                onChanged: family.search,
                style: AppTextStyles.fieldValue,
                decoration: InputDecoration(
                  hintText: 'Search members',
                  hintStyle: AppTextStyles.body,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _fetch,
                child: members.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 60),
                          Text(
                            'No member matches "${family.query}"',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body,
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSizes.screenPadding,
                          AppSizes.lg,
                          AppSizes.screenPadding,
                          AppSizes.xl,
                        ),
                        itemCount: members.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final m = members[i];
                          final index = family.members.indexOf(m);
                          return MemberTile(
                            member: m,
                            documentCount: saved.totalFor(m.id),
                            color:
                                AppColors.memberPalette[index %
                                    AppColors.memberPalette.length],
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.editMember,
                              arguments: m,
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IconButton.filled(
        tooltip: 'Add member',
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: const Icon(Icons.add_rounded, color: AppColors.white, size: 26),
      ),
    );
  }
}
