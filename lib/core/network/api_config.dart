/// Backend settings. Replace the base URL and paths with your real API.
class ApiConfig {
  ApiConfig._();

  /// While true the app fakes the API (OTP "123456", always 200) so the
  /// flow can be tested before the backend is ready. Set to false for real calls.
  static const bool useMockApi = true;

  static const String baseUrl = 'https://api.example.com'; // TODO: real base URL

  /// POST {"mobile": "9876543210"} → 200 {"otp": "123456"}
  static const String sendOtp = '/auth/send-otp'; // TODO: real path

  /// POST {"mobile": "9876543210", "otp": "123456"} → 200 {"token": "..."}
  static const String verifyOtp = '/auth/verify-otp'; // TODO: real path

  static const Duration timeout = Duration(seconds: 20);
}
