import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_info_banner.dart';
import '../../../core/widgets/app_primary_button.dart';
import 'widgets/phone_input_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controller = TextEditingController();
  String? _fieldError;
  String? _serverError;

  static final _mobileRegex = RegExp(r'^[6-9]\d{9}$');

  bool get _isValid => _mobileRegex.hasMatch(_controller.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_isValid) {
      setState(() => _fieldError = 'Enter a valid 10-digit mobile number');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _serverError = null);

    // Verifying screen returns an error message, or nothing on success.
    final error = await Navigator.pushNamed(
      context,
      AppRoutes.verifying,
      arguments: _controller.text,
    );
    if (!mounted) return;
    if (error is String) setState(() => _serverError = error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - AppSizes.screenPadding * 2,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: AppBackButton(),
                    ),
                    const SizedBox(height: AppSizes.xxl),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.smartphone_rounded,
                          color: AppColors.primary,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Login with your mobile number',
                      style: AppTextStyles.heading,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "We'll verify your number automatically. No OTP to type.",
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: AppSizes.xxl),
                    PhoneInputField(
                      controller: _controller,
                      isValid: _isValid,
                      errorText: _fieldError,
                      onChanged: (_) => setState(() => _fieldError = null),
                      onSubmitted: (_) => _continue(),
                    ),
                    const SizedBox(height: 28),
                    if (_serverError != null)
                      AppInfoBanner(
                        type: BannerType.error,
                        title: "Couldn't sign you in",
                        message: _serverError!,
                      )
                    else
                      const AppInfoBanner(
                        title: 'Instant sign-in',
                        message:
                            'The code arrives with the server response and is checked for you in the background.',
                      ),
                    const Spacer(),
                    const SizedBox(height: AppSizes.xl),
                    AppPrimaryButton(
                      label: _serverError != null ? 'Try again' : 'Continue',
                      leadingIcon: _serverError != null
                          ? Icons.refresh_rounded
                          : null,
                      trailingIcon: _serverError != null
                          ? null
                          : Icons.arrow_forward_rounded,
                      onPressed: _continue,
                    ),
                    const SizedBox(height: AppSizes.lg),
                    Text(
                      'By continuing you agree to the Terms and Privacy Policy',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
