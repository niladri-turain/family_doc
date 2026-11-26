/// Base URL and every API path in one place.
class ApiEndpoints {
  ApiEndpoints._();

  /// TODO: put your server address here (same as {{baseUrl}} in Postman).
  /// iOS simulator → http://localhost:PORT, Android emulator → http://10.0.2.2:PORT,
  /// real phone → your computer's LAN IP or the deployed URL.
  static const String baseUrl = 'http://192.168.0.207:3000';

  static const Duration timeout = Duration(seconds: 20);

  // Auth
  static const String requestOtp = '/api/v1/auth/otp/request';
  static const String verifyOtp = '/api/v1/auth/otp/verify';
  static const String logout = '/api/v1/auth/logout';

  // User
  static const String me = '/api/v1/users/me';

  // Family members (bearer token required)
  static const String familyMembers = '/api/v1/family-members';
  static String familyMember(int id) => '$familyMembers/$id';

  // Document categories
  static const String categories = '/api/v1/categories';
  static const String userCategories = '/api/v1/user-categories';
  static String userCategory(int id) => '$userCategories/$id';
}
