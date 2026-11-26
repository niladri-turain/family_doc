import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/document_category.dart';
import '../providers/category_provider.dart';

/// Bottom sheet to create a category (POST /api/v1/user-categories), or to
/// edit one of the user's own categories when [category] is given (PATCH).
/// Returns the saved category, or null if closed.
Future<DocumentCategory?> showAddCategorySheet(
  BuildContext context, {
  DocumentCategory? category,
}) {
  return showModalBottomSheet<DocumentCategory>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _AddCategorySheet(category: category),
  );
}

class _AddCategorySheet extends StatefulWidget {
  const _AddCategorySheet({this.category});

  /// Editing this category; null when adding.
  final DocumentCategory? category;

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  late final _name = TextEditingController(text: widget.category?.name);
  late final _description = TextEditingController(
    text: widget.category?.description,
  );

  bool get _editing => widget.category != null;
  String? _nameError;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Enter a category name');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    try {
      final provider = context.read<CategoryProvider>();
      final editing = widget.category;
      final category = editing == null
          ? await provider.addCategory(
              name: name,
              description: _description.text,
            )
          : await provider.updateCategory(
              editing,
              name: name,
              description: _description.text,
            );
      if (mounted) Navigator.pop(context, category);
    } on ApiException catch (e) {
      setState(() {
        if (e.code == 'CATEGORY_EXISTS' || e.statusCode == 409) {
          _nameError = e.message;
        } else {
          _error = e.message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<CategoryProvider>().isSaving;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenPadding,
            12,
            AppSizes.screenPadding,
            AppSizes.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _editing ? 'Edit category' : 'New category',
                style: AppTextStyles.title.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                _editing
                    ? 'Rename it or change its description.'
                    : 'Group documents your own way, e.g. Invoices or Vehicle papers.',
                style: AppTextStyles.small,
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'Category name',
                controller: _name,
                hintText: 'e.g. Invoices',
                textCapitalization: TextCapitalization.words,
                inputFormatters: [LengthLimitingTextInputFormatter(100)],
                errorText: _nameError,
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Description',
                optionalHint: '(optional)',
                controller: _description,
                hintText: 'e.g. Bills, Receipts',
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [LengthLimitingTextInputFormatter(500)],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              AppPrimaryButton(
                label: _editing ? 'Save changes' : 'Add category',
                isLoading: saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
