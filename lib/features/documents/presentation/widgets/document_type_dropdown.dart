import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../categories/presentation/category_style.dart';
import '../../data/models/document_type.dart';

/// "All types ⌄" box that opens in place into the list of document types.
/// [selected] null means All types. With [allLabel] null there is no
/// "All" option and [hint] shows until a type is picked (upload sheet).
class DocumentTypeDropdown extends StatefulWidget {
  const DocumentTypeDropdown({
    super.key,
    required this.types,
    required this.selected,
    required this.style,
    required this.onChanged,
    this.allLabel = 'All types',
    this.allCount = 0,
    this.hint = 'Choose a type',
    this.error = false,
    this.onAdd,
    this.onRemove,
  });

  /// Shows "+ Add new type" at the end of the list.
  final VoidCallback? onAdd;

  /// Shows a delete button on the user's own types.
  final ValueChanged<DocumentType>? onRemove;

  final String? allLabel;

  /// Shown as "All types (5)" when above 0.
  final int allCount;
  final String hint;

  /// Red border (nothing picked when saving).
  final bool error;

  final List<DocumentType> types;
  final DocumentType? selected;
  final CategoryStyle style;
  final ValueChanged<DocumentType?> onChanged;

  @override
  State<DocumentTypeDropdown> createState() => _DocumentTypeDropdownState();
}

class _DocumentTypeDropdownState extends State<DocumentTypeDropdown> {
  bool _open = false;

  void _pick(DocumentType? type) {
    setState(() => _open = false);
    if (type?.id != widget.selected?.id) widget.onChanged(type);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final color = widget.style.color;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _open
              ? AppColors.primary
              : widget.error
              ? AppColors.error
              : AppColors.border,
          width: _open ? 1.5 : 1,
        ),
        boxShadow: _open
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => setState(() => _open = !_open),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          selected == null
                              ? widget.style.icon
                              : Icons.description_outlined,
                          size: 18,
                          color: color.foreground,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selected?.name ?? _allText ?? widget.hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle.copyWith(
                            color: selected == null && widget.allLabel == null
                                ? AppColors.disabledText
                                : null,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _open
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_open) ...[
                const Divider(height: 1, color: AppColors.border),
                if (widget.allLabel != null) _option(null, widget.allLabel!),
                for (final t in widget.types) _option(t, t.name),
                if (widget.onAdd != null) _addRow(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? get _allText {
    final label = widget.allLabel;
    if (label == null) return null;
    return widget.allCount > 0 ? '$label (${widget.allCount})' : label;
  }

  Widget _addRow() => Material(
    color: AppColors.white,
    child: InkWell(
      onTap: () {
        setState(() => _open = false);
        widget.onAdd!();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 18,
                color: AppColors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Add new type',
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _option(DocumentType? type, String label) {
    final active = type?.id == widget.selected?.id;
    return Material(
      color: active ? AppColors.primarySoft : AppColors.white,
      child: InkWell(
        onTap: () => _pick(type),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    color: active ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (active)
                const Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              if (type != null && type.isCustom && widget.onRemove != null)
                IconButton(
                  tooltip: 'Remove $label',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() => _open = false);
                    widget.onRemove!(type);
                  },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
