import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Label + rounded field with the indigo focus ring and an optional error.
/// Set [readOnly] + [onTap] to use it as a picker (date, dropdown…).
/// [locked] shows a grey, non-editable field with a lock icon.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.optionalHint,
    this.controller,
    this.hintText,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.prefixText,
    this.suffixIcon,
    this.readOnly = false,
    this.locked = false,
    this.onTap,
    this.onChanged,
  });

  final String label;

  /// Grey text after the label, e.g. "(optional)".
  final String? optionalHint;
  final TextEditingController? controller;
  final String? hintText;
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final String? prefixText;
  final IconData? suffixIcon;
  final bool readOnly;
  final bool locked;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final readOnly = widget.readOnly || widget.locked;
    final focused = _focus.hasFocus && !readOnly;
    // Picker (date, dropdown…): the whole box is the tap target, not only
    // the text — padding and the icon open it too.
    final picker = readOnly && widget.onTap != null;
    final highlight = focused || hasError;
    final borderColor = hasError
        ? AppColors.error
        : (focused ? AppColors.primary : AppColors.border);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: widget.label, style: AppTextStyles.label),
              if (widget.optionalHint != null)
                TextSpan(
                  text: ' ${widget.optionalHint}',
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: picker ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: widget.locked ? AppColors.surface : AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: highlight ? 2 : 1.5,
              ),
              boxShadow: highlight
                  ? [
                      BoxShadow(
                        color: hasError
                            ? AppColors.errorSoft
                            : AppColors.primarySoft,
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Row(
              children: [
                if (widget.prefixText != null) ...[
                  Text(
                    widget.prefixText!,
                    style: AppTextStyles.fieldValue.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: IgnorePointer(
                    ignoring: picker,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      readOnly: readOnly,
                      enableInteractiveSelection: !widget.locked,
                      onTap: picker ? null : widget.onTap,
                      onChanged: widget.onChanged,
                      keyboardType: widget.keyboardType,
                      inputFormatters: widget.inputFormatters,
                      textCapitalization: widget.textCapitalization,
                      style: widget.locked
                          ? AppTextStyles.fieldValue.copyWith(
                              color: AppColors.textSecondary,
                            )
                          : AppTextStyles.fieldValue,
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: widget.hintText,
                        hintStyle: AppTextStyles.fieldValue.copyWith(
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.suffixIcon != null || widget.locked)
                  Icon(
                    widget.locked
                        ? Icons.lock_outline_rounded
                        : widget.suffixIcon,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
