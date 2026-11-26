import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/app_primary_button.dart';
import 'widgets/welcome_illustration.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.screenPadding,
              AppSizes.xl,
              AppSizes.screenPadding,
              AppSizes.xl,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - AppSizes.xl * 2,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: AppLogo(),
                    ),
                    const SizedBox(height: 36),
                    const WelcomeIllustration(),
                    const SizedBox(height: AppSizes.xxl),
                    Text(AppStrings.welcomeTitle, style: AppTextStyles.display),
                    const SizedBox(height: AppSizes.md),
                    Text(AppStrings.welcomeSubtitle, style: AppTextStyles.body),
                    const Spacer(),
                    const SizedBox(height: AppSizes.xl),
                    AppPrimaryButton(
                      label: AppStrings.getStarted,
                      trailingIcon: Icons.arrow_forward_rounded,
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.login),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            AppStrings.savedPrivately,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
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
