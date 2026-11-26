import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/auth_repository.dart';
import 'widgets/verify_step_row.dart';

/// Opened with the mobile number as route argument.
/// Calls send-OTP, takes the OTP from the response, calls verify-OTP.
/// 200 → Family screen. Error → pops back to Login with the message.
class VerifyingScreen extends StatefulWidget {
  const VerifyingScreen({super.key, AuthRepository? repository})
      : _repository = repository;

  final AuthRepository? _repository;

  @override
  State<VerifyingScreen> createState() => _VerifyingScreenState();
}

class _VerifyingScreenState extends State<VerifyingScreen> {
  late final AuthRepository _repo = widget._repository ?? AuthRepository();
  final _watch = Stopwatch();
  int _step = 0; // 0 = sending, 2 = OTP received + signing in
  String? _otpAt;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final mobile = ModalRoute.of(context)!.settings.arguments as String;
    _run(mobile);
  }

  String _elapsed() =>
      '${(_watch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s';

  Future<void> _run(String mobile) async {
    _watch.start();
    try {
      final otp = await _repo.sendOtp(mobile);
      if (!mounted) return;
      setState(() {
        _step = 2;
        _otpAt = _elapsed();
      });
      await _repo.verifyOtp(mobile, otp);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.members, (route) => false);
    } on AuthException catch (e) {
      if (mounted) Navigator.pop(context, e.message);
    }
  }

  String get _formatted {
    final m = ModalRoute.of(context)!.settings.arguments as String;
    return m.length == 10 ? '+91 ${m.substring(0, 5)} ${m.substring(5)}' : m;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
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
                            color: AppColors.primarySoft, shape: BoxShape.circle),
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
                        child: const Icon(Icons.verified_user_outlined,
                            color: AppColors.white, size: 30),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                Text('Verifying your number',
                    style: AppTextStyles.title.copyWith(fontSize: 24)),
                const SizedBox(height: 10),
                Text('$_formatted · this takes a few seconds',
                    textAlign: TextAlign.center, style: AppTextStyles.body),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      VerifyStepRow(
                        label: 'Login request sent',
                        status:
                            _step == 0 ? StepStatus.running : StepStatus.done,
                      ),
                      VerifyStepRow(
                        label: 'OTP received from server',
                        status: _step >= 2 ? StepStatus.done : StepStatus.pending,
                        trailing: _otpAt,
                      ),
                      VerifyStepRow(
                        label: 'Signing you in…',
                        status:
                            _step >= 2 ? StepStatus.running : StepStatus.pending,
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
