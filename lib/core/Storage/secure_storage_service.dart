import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test/core/constants/app_constants.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    // iOptions : IOSOptions( accessibility: IOSAccessibility.first_unlock),
  );

  Future<void> saveToken({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
    await _storage.write(
      key: AppConstants.refreshTokenKey,
      value: refreshToken,
    );
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConstants.refreshTokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }

  Future<bool> hasToken() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<void> saveUser({
    required String id,
    required String username,
    required String name,
  }) async{
    await _storage.write(key: AppConstants.userIdKey, value: id);
    await _storage.write(key: AppConstants.usernameKey, value: username);
    await _storage.write(key: AppConstants.userNameKey, value: name);
  }

  Future<Map<String, String>?> getCachedUser()async{
    final id = await _storage.read(key: AppConstants.userIdKey);
    final username = await _storage.read(key: AppConstants.userNameKey);
    final name = await _storage.read(key: AppConstants.userNameKey);

    if(id == null || username == null || name == null) return null;
    return {'id': id, 'username': username, 'name': name};
  }
}
