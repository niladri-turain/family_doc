import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// "+91 | 9876543210 ✓" field with focus, valid and error states.
class PhoneInputField extends StatefulWidget {
  const PhoneInputField({
    super.key,
    required this.controller,
    this.isValid = false,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool isValid;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
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
    final active = _focus.hasFocus || hasError;
    final borderColor = hasError
        ? AppColors.error
        : (_focus.hasFocus ? AppColors.primary : AppColors.border);
    final ringColor = hasError ? AppColors.errorSoft : AppColors.primarySoft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mobile number', style: AppTextStyles.label),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: active ? 2 : 1.5),
            boxShadow: active
                ? [BoxShadow(color: ringColor, spreadRadius: 4)]
                : null,
            color: AppColors.white,
          ),
          child: Row(
            children: [
              Text(
                '+91',
                style: AppTextStyles.input.copyWith(letterSpacing: 0),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 26, color: AppColors.border),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: AppTextStyles.input,
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    hintText: '98765 43210',
                    hintStyle: AppTextStyles.input.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                ),
              ),
              if (widget.isValid && !hasError)
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: AppColors.white,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.errorText ?? '10-digit number registered with your account',
          style: AppTextStyles.caption.copyWith(
            color: hasError ? AppColors.error : AppColors.textSecondary,
            fontWeight: hasError ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
