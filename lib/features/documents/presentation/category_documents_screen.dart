import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/category_icon_box.dart';
import '../../../core/widgets/skeleton_line.dart';
import '../../categories/data/models/document_category.dart';
import '../../categories/presentation/category_style.dart';
import '../../family/data/models/family_member.dart';
import '../data/document_service.dart';
import '../data/file_actions.dart';
import '../data/models/document_type.dart';
import '../data/models/saved_document.dart';
import 'providers/document_provider.dart';
import 'widgets/document_type_dropdown.dart';
import 'widgets/document_actions_sheet.dart';
import 'widgets/document_tile.dart';
import 'widgets/documents_empty_state.dart';
import 'widgets/expiry_widgets.dart';
import 'widgets/rename_document_sheet.dart';
import 'widgets/upload_document_sheet.dart';

/// Route argument for [CategoryDocumentsScreen].
class CategoryDocumentsArgs {
  const CategoryDocumentsArgs({required this.category, this.member});

  final DocumentCategory category;
  final FamilyMember? member;
}

/// One category's documents for a member (saved on this phone), with a
/// document type filter (types from GET /api/v1/document-types?categoryId=).
/// Tap a document to open it, share it from its button, ⋮ to rename or delete.
/// Long press starts selecting; then taps add or remove documents and the
/// bottom button shares all the selected ones together.
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

  /// Ids of the documents picked for sharing; empty when not selecting.
  final Set<String> _picked = {};
  bool get _selecting => _picked.isNotEmpty;

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

  Future<void> _upload() async {
    final args = _args!;
    final member = args.member;
    if (member == null) {
      _snack('Add yourself or a family member first.');
      return;
    }
    await showUploadDocumentSheet(
      context,
      category: args.category,
      member: member,
      types: _types,
      initialType: _selected,
    );
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _open(SavedDocument document) async {
    final path = await context.read<DocumentProvider>().pathOf(document);
    final error = await sl<FileActions>().open(path);
    if (error != null && mounted) _snack(error);
  }

  Future<void> _share(SavedDocument document, Rect? origin) async {
    final path = await context.read<DocumentProvider>().pathOf(document);
    try {
      await sl<FileActions>().share(path, name: document.name, origin: origin);
    } catch (_) {
      if (mounted) _snack('Could not share this file.');
    }
  }

  void _toggle(SavedDocument document) => setState(() {
    if (!_picked.remove(document.id)) _picked.add(document.id);
  });

  void _clearSelection() => setState(_picked.clear);

  Future<void> _shareSelected(List<SavedDocument> documents) async {
    if (documents.isEmpty) return;
    final provider = context.read<DocumentProvider>();
    try {
      final paths = [for (final d in documents) await provider.pathOf(d)];
      await sl<FileActions>().shareAll(paths);
      if (mounted) _clearSelection();
    } catch (_) {
      if (mounted) _snack('Could not share these files.');
    }
  }

  Future<void> _more(SavedDocument document) async {
    final action = await showDocumentActionsSheet(context, document);
    if (!mounted || action == null) return;
    switch (action) {
      case DocumentAction.open:
        await _open(document);
      case DocumentAction.rename:
        await showRenameDocumentSheet(context, document);
      case DocumentAction.expiry:
        final date = await pickExpiryDate(
          context,
          initial: document.expiryDate,
        );
        if (date != null && mounted) {
          await context.read<DocumentProvider>().setExpiry(document, date);
        }
      case DocumentAction.removeExpiry:
        await context.read<DocumentProvider>().setExpiry(document, null);
      case DocumentAction.share:
        await _share(document, null);
      case DocumentAction.delete:
        await _delete(document);
    }
  }

  Future<void> _delete(SavedDocument document) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Delete ${document.name}?',
      message:
          "The file will be removed from this phone. This can't be undone.",
      confirmLabel: 'Delete',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<DocumentProvider>().remove(document);
    } catch (_) {
      if (mounted) _snack('Could not delete this file.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;
    if (args == null) {
      return const Scaffold(body: Center(child: Text('Category not found')));
    }
    final category = args.category;
    final style = CategoryStyle.of(category.name);
    final all = context.watch<DocumentProvider>().documentsFor(
      args.member?.id,
      category,
    );
    final selected = _selected;
    final documents = selected == null
        ? all
        : all.where((d) => d.typeId == selected.id).toList();
    // Drop picks that were deleted or filtered out.
    _picked.retainWhere((id) => documents.any((d) => d.id == id));
    final picked = documents.where((d) => _picked.contains(d.id)).toList();
    final count = all.length;
    final subtitle = [
      if (args.member != null) args.member!.fullName,
      '$count ${count == 1 ? 'document' : 'documents'}',
    ].join(' · ');

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSelection();
      },
      child: Scaffold(
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
                    if (_selecting)
                      _selectionBar(picked.length, documents)
                    else
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
                                  style: AppTextStyles.title.copyWith(
                                    fontSize: 20,
                                  ),
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
                    ..._typeFilter(style, count),
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
                    padding: EdgeInsets.fromLTRB(
                      AppSizes.screenPadding,
                      documents.isEmpty ? 40 : AppSizes.lg,
                      AppSizes.screenPadding,
                      AppSizes.xl,
                    ),
                    children: documents.isEmpty
                        ? [_empty(category)]
                        : [
                            for (final d in documents) ...[
                              DocumentTile(
                                document: d,
                                selecting: _selecting,
                                selected: _picked.contains(d.id),
                                onOpen: () =>
                                    _selecting ? _toggle(d) : _open(d),
                                onLongPress: () => _toggle(d),
                                onShare: (origin) => _share(d, origin),
                                onMore: () => _more(d),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
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
                child: _selecting
                    ? AppPrimaryButton(
                        label:
                            'Share ${picked.length} '
                            '${picked.length == 1 ? 'document' : 'documents'}',
                        leadingIcon: Icons.share_outlined,
                        onPressed: () => _shareSelected(picked),
                      )
                    : AppPrimaryButton(
                        label: 'Upload document',
                        leadingIcon: Icons.file_upload_outlined,
                        onPressed: _upload,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Replaces the title row while selecting: ✕, "2 selected", Select all.
  Widget _selectionBar(int count, List<SavedDocument> documents) {
    final allPicked = count == documents.length;
    return Row(
      children: [
        IconButton(
          tooltip: 'Cancel selection',
          onPressed: _clearSelection,
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Text(
            '$count selected',
            style: AppTextStyles.title.copyWith(fontSize: 20),
          ),
        ),
        TextButton(
          onPressed: () => setState(() {
            if (allPicked) {
              _picked.clear();
            } else {
              _picked.addAll(documents.map((d) => d.id));
            }
          }),
          child: Text(allPicked ? 'Clear' : 'Select all'),
        ),
      ],
    );
  }

  /// Label + dropdown; skeleton while loading, error with Retry on failure,
  /// nothing for categories without types.
  List<Widget> _typeFilter(CategoryStyle style, int documentCount) {
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
        allCount: documentCount,
        onChanged: (t) => setState(() {
          _selected = t;
          _picked.clear();
        }),
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
