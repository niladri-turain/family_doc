import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/category_icon_box.dart';
import '../../../core/widgets/skeleton_line.dart';
import '../../categories/data/models/document_category.dart';
import '../../categories/presentation/category_style.dart';
import '../../family/data/models/family_member.dart';
import '../data/document_service.dart';
import '../data/models/document_type.dart';
import 'widgets/document_type_dropdown.dart';
import 'widgets/documents_empty_state.dart';

/// Route argument for [CategoryDocumentsScreen].
class CategoryDocumentsArgs {
  const CategoryDocumentsArgs({required this.category, this.member});

  final DocumentCategory category;
  final FamilyMember? member;
}

/// One category's documents for a member, with a document type filter
/// (types from GET /api/v1/document-types?categoryId={id}).
/// Documents themselves aren't loaded yet, so the list is empty for now.
class CategoryDocumentsScreen extends StatefulWidget {
  const CategoryDocumentsScreen({super.key});

  @override
  State<CategoryDocumentsScreen> createState() =>
      _CategoryDocumentsScreenState();
}

class _CategoryDocumentsScreenState extends State<CategoryDocumentsScreen> {
  CategoryDocumentsArgs? _args;
  List<DocumentType> _types = const [];
  DocumentType? _selected;
  bool _loading = false;
  ApiException? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_args != null) return;
    _args =
        ModalRoute.of(context)?.settings.arguments as CategoryDocumentsArgs?;
    _loadTypes();
  }

  /// Types exist only for built-in categories; a user's own category ids
  /// can match a built-in id, so those are not looked up.
  Future<void> _loadTypes() async {
    final category = _args?.category;
    if (category == null || category.isCustom) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final types = await sl<DocumentService>().getDocumentTypes(category.id);
      if (!mounted) return;
      setState(() => _types = types);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _upload() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Uploading documents is coming next.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;
    if (args == null) {
      return const Scaffold(body: Center(child: Text('Category not found')));
    }
    final category = args.category;
    final style = CategoryStyle.of(category.name);
    final count = category.documentCount;
    final subtitle = [
      if (args.member != null) args.member!.fullName,
      '$count ${count == 1 ? 'document' : 'documents'}',
    ].join(' · ');

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.lg,
                AppSizes.screenPadding,
                AppSizes.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const AppBackButton(),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.title.copyWith(fontSize: 20),
                            ),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      CategoryIconBox(icon: style.icon, color: style.color),
                    ],
                  ),
                  ..._typeFilter(style),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _loadTypes,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.screenPadding,
                    40,
                    AppSizes.screenPadding,
                    AppSizes.xl,
                  ),
                  children: [_empty(category)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.sm,
                AppSizes.screenPadding,
                AppSizes.lg,
              ),
              child: AppPrimaryButton(
                label: 'Upload document',
                leadingIcon: Icons.file_upload_outlined,
                onPressed: _upload,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Label + dropdown; skeleton while loading, error with Retry on failure,
  /// nothing for categories without types.
  List<Widget> _typeFilter(CategoryStyle style) {
    final Widget box;
    if (_loading && _types.isEmpty) {
      box = Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.centerLeft,
        child: const SkeletonLine(width: 140, height: 14),
      );
    } else if (_error != null && _types.isEmpty) {
      box = Container(
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        decoration: BoxDecoration(
          color: AppColors.errorSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.errorBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _error!.message,
                style: AppTextStyles.small.copyWith(color: AppColors.errorText),
              ),
            ),
            TextButton(onPressed: _loadTypes, child: const Text('Retry')),
          ],
        ),
      );
    } else if (_types.isEmpty) {
      return const [];
    } else {
      box = DocumentTypeDropdown(
        types: _types,
        selected: _selected,
        style: style,
        onChanged: (t) => setState(() => _selected = t),
      );
    }
    return [
      const SizedBox(height: AppSizes.lg),
      Text('Document type', style: AppTextStyles.label),
      const SizedBox(height: AppSizes.sm),
      box,
    ];
  }

  Widget _empty(DocumentCategory category) {
    final selected = _selected;
    if (selected != null) {
      return DocumentsEmptyState(
        title: 'No ${selected.name} yet',
        message:
            'Upload it once and it stays here, ready to open or share '
            'whenever you need it.',
      );
    }
    return DocumentsEmptyState(
      title: 'No ${category.name.toLowerCase()} documents yet',
      message: _types.isEmpty
          ? 'Upload documents to keep them safe and easy to find.'
          : 'Choose the type first so they stay organised.',
      types: _types,
      onTypeTap: (t) => setState(() => _selected = t),
    );
  }
}
