import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import 'providers/auth_provider.dart';
import 'widgets/verify_step_row.dart';

/// Opened with the 10-digit mobile number as route argument.
/// Runs [AuthProvider.login]: request OTP → verify with that OTP → save token.
/// Success → My Family. Failure → back to Login with the error message.
class VerifyingScreen extends StatefulWidget {
  const VerifyingScreen({super.key});

  @override
  State<VerifyingScreen> createState() => _VerifyingScreenState();
}

class _VerifyingScreenState extends State<VerifyingScreen> {
  late final String _mobile =
      ModalRoute.of(context)!.settings.arguments as String;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _login());
  }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_mobile);
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.family,
        (_) => false,
      );
    } else {
      Navigator.pop(context, auth.error);
    }
  }

  String get _formatted => _mobile.length == 10
      ? '+91 ${_mobile.substring(0, 5)} ${_mobile.substring(5)}'
      : _mobile;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final otpDone =
        auth.step == AuthStep.verifyingOtp || auth.step == AuthStep.success;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenPadding,
            ),
            child: Column(
              children: [
                const SizedBox(height: 90),
                SizedBox(
                  width: 132,
                  height: 132,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox.expand(
                        child: CircularProgressIndicator(
                          strokeWidth: 6,
                          color: AppColors.primary,
                          backgroundColor: AppColors.primarySofter,
                        ),
                      ),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  'Verifying your number',
                  style: AppTextStyles.title.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  '$_formatted · this takes a few seconds',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      VerifyStepRow(
                        label: 'Login request sent',
                        status: otpDone ? StepStatus.done : StepStatus.running,
                      ),
                      VerifyStepRow(
                        label: 'OTP received from server',
                        status: otpDone ? StepStatus.done : StepStatus.pending,
                        trailing: otpDone ? auth.otpReceivedIn : null,
                      ),
                      VerifyStepRow(
                        label: 'Signing you in…',
                        status: auth.step == AuthStep.success
                            ? StepStatus.done
                            : (otpDone
                                  ? StepStatus.running
                                  : StepStatus.pending),
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
