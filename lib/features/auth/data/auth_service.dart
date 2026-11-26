import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'models/otp_request_response.dart';
import 'models/user_model.dart';
import 'models/verify_otp_response.dart';

/// Auth and current-user API calls.
class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  /// Body matches Postman: {"mobile": "+919876543210"}
  Future<OtpRequestResponse> requestOtp(String mobile) async {
    final data = await _api.post(
      ApiEndpoints.requestOtp,
      body: {'mobile': mobile},
      auth: false,
    );
    return OtpRequestResponse.fromJson(data as Map<String, dynamic>);
  }

  /// Body matches Postman: {"mobile": "7059238072", "otp": "504709"}
  Future<VerifyOtpResponse> verifyOtp(String mobile, String otp) async {
    final data = await _api.post(
      ApiEndpoints.verifyOtp,
      body: {'mobile': mobile, 'otp': otp},
      auth: false,
    );
    return VerifyOtpResponse.fromJson(data as Map<String, dynamic>);
  }

  /// GET /api/v1/users/me → {"user": {"id", "mobile", "createdAt"}}
  Future<UserModel> getMe() async {
    final data = await _api.get(ApiEndpoints.me);
    return UserModel.fromJson(
      (data as Map<String, dynamic>)['user'] as Map<String, dynamic>,
    );
  }

  /// POST /api/v1/auth/logout {"refreshToken": "..."} → 204
  Future<void> logout(String refreshToken) =>
      _api.post(ApiEndpoints.logout, body: {'refreshToken': refreshToken});
}
