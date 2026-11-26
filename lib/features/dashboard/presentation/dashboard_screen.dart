import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/skeleton_line.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../categories/data/models/document_category.dart';
import '../../categories/presentation/providers/category_provider.dart';
import '../../categories/presentation/widgets/add_category_sheet.dart';
import '../../documents/presentation/category_documents_screen.dart';
import '../../family/data/models/family_member.dart';
import '../../family/presentation/providers/family_provider.dart';
import 'widgets/add_category_button.dart';
import 'widgets/category_actions_sheet.dart';
import 'widgets/category_card.dart';
import 'widgets/member_switcher.dart';
import 'widgets/total_documents_card.dart';

/// Member switcher, total documents and the category grid
/// (categories from GET /api/v1/categories; counts are 0 until uploads exist).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final family = context.read<FamilyProvider>();
    final categories = context.read<CategoryProvider>();
    await Future.wait([
      if (!family.hasLoaded) family.fetchMembers(),
      categories.fetchCategories(),
    ]);
    final unauthorized =
        (categories.error?.isUnauthorized ?? false) ||
        (family.error?.isUnauthorized ?? false);
    if (unauthorized && mounted) await _sessionExpired();
  }

  Future<void> _sessionExpired() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    context.read<FamilyProvider>().clear();
    context.read<CategoryProvider>().clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your session has expired. Please log in again.'),
      ),
    );
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.welcome, (_) => false);
  }

  /// Selected member, else Self, else the first one.
  FamilyMember? _selected(FamilyProvider family) {
    final members = family.members;
    if (members.isEmpty) return null;
    for (final m in members) {
      if (m.id == _selectedId) return m;
    }
    return family.self ?? members.first;
  }

  Future<void> _pickMember(FamilyProvider family, FamilyMember current) async {
    final picked = await showMemberPicker(
      context,
      members: family.members,
      selectedId: current.id,
    );
    if (picked != null) setState(() => _selectedId = picked.id);
  }

  void _openCategory(DocumentCategory category, FamilyMember? member) {
    Navigator.pushNamed(
      context,
      AppRoutes.categoryDocuments,
      arguments: CategoryDocumentsArgs(category: category, member: member),
    );
  }

  /// New card shows up at the end of the grid; no success snackbar.
  Future<void> _addCategory() => showAddCategorySheet(context);

  /// ⋯ on a custom category → Edit (same sheet, prefilled) or Delete.
  Future<void> _categoryActions(DocumentCategory category) async {
    final action = await showCategoryActionsSheet(context, category);
    if (!mounted || action == null) return;
    switch (action) {
      case CategoryAction.edit:
        await showAddCategorySheet(context, category: category);
      case CategoryAction.delete:
        await _deleteCategory(category);
    }
  }

  Future<void> _deleteCategory(DocumentCategory category) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Delete ${category.name}?',
      message:
          'This category will be removed from your dashboard. '
          "This can't be undone.",
      confirmLabel: 'Delete',
    );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<CategoryProvider>().deleteCategory(category);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>();
    final categoryState = context.watch<CategoryProvider>();
    final member = _selected(family);
    final categories = categoryState.categories;
    final total = categoryState.totalDocuments;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => Future.wait([
            family.fetchMembers(),
            categoryState.fetchCategories(),
          ]),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSizes.screenPadding,
              AppSizes.lg,
              AppSizes.screenPadding,
              AppSizes.xl,
            ),
            children: [
              _header(family, member),
              const SizedBox(height: 20),
              TotalDocumentsCard(
                total: total,
                categoryCount: categories.length,
                filledCategories: categories
                    .where((c) => c.documentCount > 0)
                    .length,
              ),
              const SizedBox(height: 24),
              Text(
                'Categories',
                style: AppTextStyles.title.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 12),
              _categories(categoryState, member),
              if (categoryState.hasLoaded) ...[
                const SizedBox(height: 16),
                AddCategoryButton(onTap: _addCategory),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(FamilyProvider family, FamilyMember? member) {
    return Row(
      children: [
        Flexible(
          child: Align(
            alignment: Alignment.centerLeft,
            child: member != null
                ? MemberSwitcher(
                    member: member,
                    onTap: () => _pickMember(family, member),
                  )
                : family.hasLoaded
                ? TextButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.addMember,
                      arguments: true,
                    ),
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Add yourself'),
                  )
                : const SkeletonLine(width: 160, height: 44),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          child: IconButton(
            tooltip: 'Search',
            onPressed: () => ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text('Search is coming soon.')),
              ),
            icon: const Icon(Icons.search_rounded),
            color: AppColors.textPrimary,
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          ),
        ),
      ],
    );
  }

  Widget _categories(CategoryProvider state, FamilyMember? member) {
    final error = state.error;
    if (!state.hasLoaded && error != null) {
      return _CategoriesError(error: error, onRetry: state.fetchCategories);
    }
    if (!state.hasLoaded) {
      return _grid([for (var i = 0; i < 4; i++) const _CategorySkeleton()]);
    }
    if (state.categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No categories yet',
          textAlign: TextAlign.center,
          style: AppTextStyles.body,
        ),
      );
    }
    return _grid([
      for (final c in state.categories)
        CategoryCard(
          category: c,
          onTap: () => _openCategory(c, member),
          onMore: c.isCustom ? () => _categoryActions(c) : null,
        ),
    ]);
  }

  Widget _grid(List<Widget> children) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: EdgeInsets.zero,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 1.3,
    children: children,
  );
}

class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLine(width: 44, height: 44),
          Spacer(),
          SkeletonLine(width: 90, height: 12),
          SizedBox(height: 8),
          SkeletonLine(width: 70, height: 8, light: true),
        ],
      ),
    );
  }
}

class _CategoriesError extends StatelessWidget {
  const _CategoriesError({required this.error, required this.onRetry});

  final ApiException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Column(
        children: [
          Text(
            error.message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.errorText),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
