import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Prints every API call to the debug console (only in debug builds).
///
/// ┌── 🚀 REQUEST POST
/// │ URL: http://.../api/v1/auth/otp/request
/// │ Body: {...}
/// ├── ✅ RESPONSE 200 (57 ms)
/// │ {...}
/// └──────────
class ApiLogger {
  ApiLogger._();

  static const _encoder = JsonEncoder.withIndent('  ');

  static void request({
    required String method,
    required Uri url,
    required Map<String, String> headers,
    Object? body,
  }) {
    if (!kDebugMode) return;
    final auth = headers['Authorization'];
    _print([
      '┌── 🚀 REQUEST $method',
      '│ URL: $url',
      if (auth != null) '│ Authorization: ${_shorten(auth)}',
      if (body != null) '│ Body:\n${_pretty(body)}',
    ]);
  }

  static void response({
    required String method,
    required Uri url,
    required int statusCode,
    required Duration took,
    required String body,
  }) {
    if (!kDebugMode) return;
    final ok = statusCode >= 200 && statusCode < 300;
    _print([
      '├── ${ok ? '✅' : '❌'} RESPONSE $statusCode  $method $url  (${took.inMilliseconds} ms)',
      if (body.isNotEmpty) _pretty(_tryDecode(body)),
      '└──────────────────────────',
    ]);
  }

  static void error({
    required String method,
    required Uri url,
    required Object error,
  }) {
    if (!kDebugMode) return;
    _print([
      '├── ⚠️ FAILED  $method $url',
      '│ $error',
      '└──────────────────────────',
    ]);
  }

  static Object _tryDecode(String body) {
    try {
      return jsonDecode(body) as Object;
    } on FormatException {
      return body;
    }
  }

  static String _pretty(Object value) {
    try {
      return _encoder.convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  /// "Bearer eyJhbGciOi…k9d6nb" — enough to recognise, not the whole token.
  static String _shorten(String value) => value.length > 32
      ? '${value.substring(0, 18)}…${value.substring(value.length - 6)}'
      : value;

  static void _print(List<String> lines) {
    // debugPrint wraps long lines instead of cutting them off.
    debugPrint(lines.join('\n'), wrapWidth: 1024);
  }
}
