import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../categories/data/models/document_category.dart';
import '../../data/models/document_type.dart';
import '../providers/document_provider.dart';

/// "Add document type" popup. Returns the typed name, or null if closed.
/// [existing] are the category's type names (no duplicates allowed).
Future<String?> showAddDocumentTypeDialog(
  BuildContext context, {
  required String categoryName,
  required List<String> existing,
}) => showDialog<String>(
  context: context,
  builder: (_) =>
      _AddTypeDialog(categoryName: categoryName, existing: existing),
);

/// Asks for a name and saves it as one of the user's types in [category].
/// Returns the new type, or null if closed.
Future<DocumentType?> addDocumentType(
  BuildContext context,
  DocumentCategory category, {
  required List<DocumentType> existing,
}) async {
  final documents = context.read<DocumentProvider>();
  final name = await showAddDocumentTypeDialog(
    context,
    categoryName: category.name,
    existing: [for (final t in existing) t.name],
  );
  if (name == null) return null;
  return documents.addCustomType(category, name);
}

class _AddTypeDialog extends StatefulWidget {
  const _AddTypeDialog({required this.categoryName, required this.existing});

  final String categoryName;
  final List<String> existing;

  @override
  State<_AddTypeDialog> createState() => _AddTypeDialogState();
}

class _AddTypeDialogState extends State<_AddTypeDialog> {
  final _name = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final taken = widget.existing.any(
      (e) => e.toLowerCase() == name.toLowerCase(),
    );
    setState(
      () => _error = name.isEmpty
          ? 'Enter a type name'
          : taken
          ? '"$name" is already in ${widget.categoryName}'
          : null,
    );
    if (_error == null) Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Add document type',
                    style: AppTextStyles.title.copyWith(fontSize: 18),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Text(
              'It will show in ${widget.categoryName} for every member.',
              style: AppTextStyles.small,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Type name',
              controller: _name,
              hintText: 'e.g. 10th Admit Card',
              textCapitalization: TextCapitalization.words,
              inputFormatters: [LengthLimitingTextInputFormatter(60)],
              errorText: _error,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              label: 'Add type',
              leadingIcon: Icons.add_rounded,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
