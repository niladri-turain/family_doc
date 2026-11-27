import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/saved_document.dart';
import '../providers/document_provider.dart';

/// Sheet with the document name prefilled; saving renames the file too.
Future<SavedDocument?> showRenameDocumentSheet(
  BuildContext context,
  SavedDocument document,
) {
  return showModalBottomSheet<SavedDocument>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _RenameSheet(document: document),
  );
}

class _RenameSheet extends StatefulWidget {
  const _RenameSheet({required this.document});

  final SavedDocument document;

  @override
  State<_RenameSheet> createState() => _RenameSheetState();
}

class _RenameSheetState extends State<_RenameSheet> {
  late final _name = TextEditingController(text: widget.document.name)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.document.name.length,
    );
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a document name');
      return;
    }
    if (name == widget.document.name) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = true);
    try {
      final renamed = await context.read<DocumentProvider>().rename(
        widget.document,
        name,
      );
      if (mounted) Navigator.pop(context, renamed);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not rename this file. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final typed = _name.text.trim();
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
                'Rename document',
                style: AppTextStyles.title.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'Document name',
                controller: _name,
                hintText: 'e.g. B.Sc Final Marksheet',
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [LengthLimitingTextInputFormatter(100)],
                errorText: _error,
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 6),
              Text(
                'File name: ${SavedDocument.fileNameFor(typed, widget.document.extension)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 24),
              AppPrimaryButton(
                label: 'Save name',
                isLoading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
