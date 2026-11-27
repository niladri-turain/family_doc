/// Any failed API call ends up as this. [message] is safe to show to the user.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  final String message;

  /// HTTP status code, or null when the request never reached the server.
  final int? statusCode;

  /// Server error code, e.g. "SELF_EXISTS", "FILE_TOO_LARGE".
  final String? code;

  bool get isUnauthorized => statusCode == 401;

  /// The request never got an answer (no internet, server down, timeout).
  bool get isNetworkError => statusCode == null;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
