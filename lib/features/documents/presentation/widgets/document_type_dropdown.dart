import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../categories/presentation/category_style.dart';
import '../../data/models/document_type.dart';

/// "All types ⌄" box that opens in place into the list of document types.
/// [selected] null means All types.
class DocumentTypeDropdown extends StatefulWidget {
  const DocumentTypeDropdown({
    super.key,
    required this.types,
    required this.selected,
    required this.style,
    required this.onChanged,
  });

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
          color: _open ? AppColors.primary : AppColors.border,
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
                          selected?.name ??
                              'All types (${widget.types.length})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle,
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
                _option(null, 'All types'),
                for (final t in widget.types) _option(t, t.name),
              ],
            ],
          ),
        ),
      ),
    );
  }

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
            ],
          ),
        ),
      ),
    );
  }
}
