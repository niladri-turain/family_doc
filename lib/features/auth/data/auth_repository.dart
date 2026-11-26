import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';

/// Thrown when login fails; [message] is shown to the user.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Login = two calls, no OTP typed by the user:
/// 1. [sendOtp]  → the OTP comes back in the response body.
/// 2. [verifyOtp] → sends that OTP back; HTTP 200 means logged in.
class AuthRepository {
  AuthRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> sendOtp(String mobile) async {
    if (ApiConfig.useMockApi) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      return '123456';
    }
    final body = await _post(ApiConfig.sendOtp, {'mobile': mobile});
    final otp = body['otp'] ?? (body['data'] is Map ? body['data']['otp'] : null);
    if (otp == null) {
      throw const AuthException('OTP missing in server response.');
    }
    return otp.toString();
  }

  /// Returns the auth token (empty string if the API sends none).
  Future<String> verifyOtp(String mobile, String otp) async {
    if (ApiConfig.useMockApi) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      return 'mock-token';
    }
    final body =
        await _post(ApiConfig.verifyOtp, {'mobile': mobile, 'otp': otp});
    final token =
        body['token'] ?? (body['data'] is Map ? body['data']['token'] : null);
    return token?.toString() ?? '';
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> payload) async {
    try {
      final res = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(ApiConfig.timeout);
      if (res.statusCode != 200) {
        throw AuthException(
            "The server didn't confirm your number (code ${res.statusCode}).");
      }
      final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on AuthException {
      rethrow;
    } on TimeoutException {
      throw const AuthException('The server took too long. Please try again.');
    } catch (_) {
      throw const AuthException(
          'Check your internet connection and try again.');
    }
  }
}
