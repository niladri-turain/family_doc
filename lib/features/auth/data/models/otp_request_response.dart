/// Response of POST /api/v1/auth/otp/request
/// `{"message": "OTP sent", "expiresInSeconds": 300, "devOtp": "768598"}`
class OtpRequestResponse {
  const OtpRequestResponse({
    required this.message,
    required this.expiresInSeconds,
    this.devOtp,
  });

  final String message;
  final int expiresInSeconds;

  /// The OTP sent back by the server; the app verifies with it automatically.
  final String? devOtp;

  factory OtpRequestResponse.fromJson(Map<String, dynamic> json) =>
      OtpRequestResponse(
        message: json['message']?.toString() ?? '',
        expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 0,
        devOtp: json['devOtp']?.toString(),
      );
}
