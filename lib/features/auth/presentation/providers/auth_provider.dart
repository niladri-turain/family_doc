import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/auth_service.dart';
import '../../data/models/user_model.dart';

enum AuthStep { idle, requestingOtp, verifyingOtp, success, failure }

/// Login state. Screens read it with `context.watch<AuthProvider>()`.
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthService service,
    required TokenStorage tokens,
    this.stepDelay = const Duration(milliseconds: 900),
  }) : _service = service,
       _tokens = tokens;

  final AuthService _service;
  final TokenStorage _tokens;

  /// Short pause between steps so the user can see each tick on the
  /// verifying screen (the APIs themselves answer in a few ms).
  final Duration stepDelay;

  AuthStep _step = AuthStep.idle;
  AuthStep get step => _step;

  String? _error;
  String? get error => _error;

  UserModel? _user;
  UserModel? get user => _user;

  bool _isNewUser = false;
  bool get isNewUser => _isNewUser;

  /// How long the OTP request took, e.g. "0.9s" (shown on the verifying screen).
  String? _otpReceivedIn;
  String? get otpReceivedIn => _otpReceivedIn;

  bool get isLoading =>
      _step == AuthStep.requestingOtp || _step == AuthStep.verifyingOtp;

  /// 1. request OTP → 2. verify with the OTP from that response → 3. save token.
  /// Returns true when both calls succeeded.
  Future<bool> login(String mobile) async {
    if (isLoading) return false;
    _error = null;
    _otpReceivedIn = null;
    _setStep(AuthStep.requestingOtp);
    final watch = Stopwatch()..start();
    await Future<void>.delayed(stepDelay);

    try {
      final otpResponse = await _service.requestOtp(mobile);
      final otp = otpResponse.devOtp;
      if (otp == null || otp.isEmpty) {
        throw const ApiException('OTP was not returned by the server.');
      }
      _otpReceivedIn =
          '${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s';
      _setStep(AuthStep.verifyingOtp);
      await Future<void>.delayed(stepDelay);

      final verify = await _service.verifyOtp(mobile, otp);
      if (verify.accessToken.isEmpty) {
        throw const ApiException('Login token missing in server response.');
      }
      await _tokens.saveTokens(
        accessToken: verify.accessToken,
        refreshToken: verify.refreshToken,
      );
      _user = verify.user;
      _isNewUser = verify.isNewUser;
      _setStep(AuthStep.success);
      await Future<void>.delayed(stepDelay);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Unexpected response from the server.';
    }
    _setStep(AuthStep.failure);
    return false;
  }

  Future<bool> get isLoggedIn => _tokens.hasToken;

  bool _isLoadingProfile = false;
  bool get isLoadingProfile => _isLoadingProfile;

  /// GET /users/me — fills [user] (mobile number) for the Profile screen.
  /// Throws [ApiException] so the screen can react to 401.
  Future<void> loadProfile() async {
    _isLoadingProfile = true;
    notifyListeners();
    try {
      _user = await _service.getMe();
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  /// Revokes the refresh token on the server (best effort, so logout works
  /// offline too) and removes both tokens from the phone.
  Future<void> logout() async {
    final refresh = await _tokens.refreshToken;
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _service.logout(refresh);
      } catch (_) {
        // Already expired / no internet: still log out locally.
      }
    }
    await _tokens.clear();
    _user = null;
    _setStep(AuthStep.idle);
  }

  void _setStep(AuthStep step) {
    _step = step;
    notifyListeners();
  }
}
