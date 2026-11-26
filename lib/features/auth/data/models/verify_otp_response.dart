import 'user_model.dart';

/// Response of POST /api/v1/auth/otp/verify
class VerifyOtpResponse {
  const VerifyOtpResponse({
    required this.user,
    required this.isNewUser,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  final UserModel user;
  final bool isNewUser;
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final String expiresIn;

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) =>
      VerifyOtpResponse(
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
        isNewUser: json['isNewUser'] == true,
        accessToken: json['accessToken']?.toString() ?? '',
        refreshToken: json['refreshToken']?.toString() ?? '',
        tokenType: json['tokenType']?.toString() ?? 'Bearer',
        expiresIn: json['expiresIn']?.toString() ?? '',
      );
}
