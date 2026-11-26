import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the login tokens in the phone's secure storage (Keychain / Keystore),
/// so the user stays logged in after the app is closed.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  String? _accessCache;

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _accessCache = accessToken;
    await _storage.write(key: _accessKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshKey, value: refreshToken);
    }
  }

  Future<String?> get accessToken async =>
      _accessCache ??= await _storage.read(key: _accessKey);

  Future<String?> get refreshToken => _storage.read(key: _refreshKey);

  Future<bool> get hasToken async => (await accessToken)?.isNotEmpty ?? false;

  Future<void> clear() async {
    _accessCache = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
