import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../categories/data/models/document_category.dart';
import '../../../categories/presentation/category_style.dart';
import '../../../family/data/models/family_member.dart';
import '../../data/file_actions.dart';
import '../../data/reading/document_reader.dart';
import '../../data/models/document_type.dart';
import '../../data/models/saved_document.dart';
import '../document_format.dart';
import '../providers/document_provider.dart';
import 'add_document_type_dialog.dart';
import 'document_type_dropdown.dart';
import 'expiry_widgets.dart';
import 'file_badge.dart';

/// "Upload to Education" sheet: document type (when the category has
/// types), document name, a file from Camera / Gallery / Files and an
/// optional expiry date (read from a photo on the phone when it has one).
/// Returns the saved document, or null if closed.
Future<SavedDocument?> showUploadDocumentSheet(
  BuildContext context, {
  required DocumentCategory category,
  required FamilyMember member,
  List<DocumentType> types = const [],
  DocumentType? initialType,
}) {
  return showModalBottomSheet<SavedDocument>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _UploadSheet(
      category: category,
      member: member,
      types: types,
      initialType: initialType,
    ),
  );
}

class _UploadSheet extends StatefulWidget {
  const _UploadSheet({
    required this.category,
    required this.member,
    required this.types,
    this.initialType,
  });

  final DocumentCategory category;
  final FamilyMember member;
  final List<DocumentType> types;
  final DocumentType? initialType;

  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  late DocumentType? _type = widget.initialType;
  late final _name = TextEditingController(text: widget.initialType?.name);
  XFile? _file;
  int _fileSize = 0;
  FileSource? _source;
  bool _picking = false;

  DateTime? _expiry;
  final _expiryText = TextEditingController();

  /// The expiry date came from reading the file (asks the user to check).
  bool _expiryFromScan = false;
  bool _reading = false;

  /// Text read from the file, kept for search and chat.
  String? _text;

  /// What the name field was filled with automatically (type or file name),
  /// so picking another type can replace it but not the user's own text.
  late String _autoName = _name.text;

  bool _typeError = false;
  String? _nameError;
  String? _fileError;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _expiryText.dispose();
    super.dispose();
  }

  void _setAutoName(String value) {
    if (_name.text.trim().isNotEmpty && _name.text != _autoName) return;
    _name.text = value;
    _autoName = value;
    _nameError = null;
  }

  void _pickType(DocumentType? type) {
    setState(() {
      _type = type;
      _typeError = false;
      if (type != null) _setAutoName(type.name);
    });
  }

  Future<void> _pickFile(FileSource source) async {
    if (_picking) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _picking = true;
      _source = source;
      _error = null;
    });
    try {
      final file = await sl<FileActions>().pick(source);
      if (file == null) return;
      final size = await file.length();
      if (!mounted) return;
      setState(() {
        _file = file;
        _fileSize = size;
        _fileError = null;
        final base = file.name.contains('.')
            ? file.name.substring(0, file.name.lastIndexOf('.'))
            : file.name;
        if (_type == null) _setAutoName(base.replaceAll('_', ' '));
        _text = null;
        if (_expiryFromScan) _setExpiry(null);
      });
      _readFile(file);
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(
        () => _error = e.code.contains('access_denied')
            ? 'Please allow access in Settings to add a file.'
            : 'Could not add this file. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  /// Call inside setState.
  void _setExpiry(DateTime? date, {bool scanned = false}) {
    _expiry = date;
    _expiryFromScan = date != null && scanned;
    _expiryText.text = date == null ? '' : formatDate(date);
  }

  /// Reads the photo's text on the phone; fills the expiry date when
  /// the user hasn't chosen one.
  Future<void> _readFile(XFile file) async {
    setState(() => _reading = true);
    final scan = await sl<DocumentReader>().read(file);
    if (!mounted || _file != file) return;
    setState(() {
      _reading = false;
      _text = scan?.text;
      final found = scan?.expiryDate;
      if (found != null && _expiry == null) _setExpiry(found, scanned: true);
    });
  }

  Future<void> _pickExpiry() async {
    FocusScope.of(context).unfocus();
    final date = await pickExpiryDate(context, initial: _expiry);
    if (date == null || !mounted) return;
    setState(() => _setExpiry(date));
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final needsType = widget.types.isNotEmpty;
    setState(() {
      _typeError = needsType && _type == null;
      _nameError = name.isEmpty ? 'Enter a document name' : null;
      _fileError = _file == null
          ? 'Add a file from Camera, Gallery or Files'
          : null;
      _error = null;
    });
    if (_typeError || _nameError != null || _fileError != null) return;
    FocusScope.of(context).unfocus();
    try {
      final document = await context.read<DocumentProvider>().add(
        file: _file!,
        name: name,
        memberId: widget.member.id,
        category: widget.category,
        type: _type,
        expiryDate: _expiry,
        text: _text,
      );
      if (mounted) Navigator.pop(context, document);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save this file. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final documents = context.watch<DocumentProvider>();
    final saving = documents.isSaving;
    final category = widget.category;
    // Server types, then the user's own (added here or in the list).
    final types = [...widget.types, ...documents.customTypesFor(category)];
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload to ${category.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.title.copyWith(fontSize: 20),
                        ),
                        Text(
                          'For ${widget.member.fullName}',
                          style: AppTextStyles.small,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              ...[
                const SizedBox(height: 20),
                Text(
                  widget.types.isEmpty
                      ? 'Document type (optional)'
                      : 'Select document type',
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: AppSizes.sm),
                DocumentTypeDropdown(
                  types: types,
                  selected: _type,
                  style: CategoryStyle.of(category.name),
                  allLabel: null,
                  error: _typeError,
                  onChanged: _pickType,
                  onAdd: () async {
                    final type = await addDocumentType(
                      context,
                      category,
                      existing: types,
                    );
                    if (type != null && mounted) _pickType(type);
                  },
                ),
                if (_typeError) _errorText('Choose a document type'),
              ],
              const SizedBox(height: 16),
              AppTextField(
                label: 'Document name',
                controller: _name,
                hintText: 'e.g. B.Sc Final Marksheet',
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [LengthLimitingTextInputFormatter(100)],
                errorText: _nameError,
                // Rebuild so the file row shows the new file name.
                onChanged: (_) => setState(() => _nameError = null),
              ),
              const SizedBox(height: 6),
              Text(
                'The file is saved and shared with this name.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 16),
              Text('Add file from', style: AppTextStyles.label),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  _sourceButton(
                    FileSource.camera,
                    Icons.photo_camera_outlined,
                    'Camera',
                  ),
                  const SizedBox(width: 10),
                  _sourceButton(
                    FileSource.gallery,
                    Icons.image_outlined,
                    'Gallery',
                  ),
                  const SizedBox(width: 10),
                  _sourceButton(
                    FileSource.files,
                    Icons.insert_drive_file_outlined,
                    'Files / PDF',
                  ),
                ],
              ),
              if (_fileError != null) _errorText(_fileError!),
              if (_file != null) ...[
                const SizedBox(height: 12),
                _pickedFile(_file!),
              ],
              const SizedBox(height: 16),
              ..._expiryField(),
              if (_error != null) _errorText(_error!),
              const SizedBox(height: 20),
              AppPrimaryButton(
                label: 'Save to ${category.name}',
                isLoading: saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _expiryField() {
    final expiry = _expiry;
    final note = _reading
        ? 'Reading the document for an expiry date…'
        : _expiryFromScan
        ? 'Found in the document. Please check it.'
        : "Add it to get a reminder before it expires.";
    return [
      AppTextField(
        label: 'Expiry date',
        optionalHint: '(optional)',
        controller: _expiryText,
        hintText: 'No expiry',
        readOnly: true,
        onTap: _pickExpiry,
        suffixIcon: Icons.event_outlined,
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          if (_reading) ...[
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              note,
              style: AppTextStyles.caption.copyWith(
                color: _expiryFromScan ? AppColors.warning : null,
              ),
            ),
          ),
          if (expiry != null)
            TextButton(
              onPressed: () => setState(() => _setExpiry(null)),
              child: const Text('Remove'),
            ),
        ],
      ),
    ];
  }

  Widget _errorText(String text) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      text,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.error,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _sourceButton(FileSource source, IconData icon, String label) {
    final active = _file != null && _source == source;
    final loading = _picking && _source == source;
    return Expanded(
      child: Material(
        color: active ? AppColors.primarySoft : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: active ? AppColors.primary : AppColors.border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _pickFile(source),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                SizedBox(
                  height: 24,
                  child: loading
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : Icon(icon, color: AppColors.primary),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pickedFile(XFile file) {
    final original = file.name.isNotEmpty
        ? file.name
        : file.path.split('/').last;
    final dot = original.lastIndexOf('.');
    final ext = dot < 0 ? '' : original.substring(dot + 1).toLowerCase();
    final typed = _name.text.trim();
    final savedAs = typed.isEmpty
        ? original
        : SavedDocument.fileNameFor(typed, ext);
    final renamed = savedAs != original;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          FileBadge(extension: ext, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  savedAs,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
                ),
                Text(
                  renamed
                      ? '${formatFileSize(_fileSize)} · renamed from $original'
                      : '${formatFileSize(_fileSize)} · ready',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove file',
            onPressed: () => setState(() {
              _file = null;
              _text = null;
              _reading = false;
              if (_expiryFromScan) _setExpiry(null);
            }),
            icon: const Icon(
              Icons.close_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
