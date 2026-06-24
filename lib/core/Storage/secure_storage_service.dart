
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test/core/constants/app_constants.dart';

class SecureStorageService{
  static const _storage = FlutterSecureStorage(
    aOptions : AndroidOptions( encryptedSharedPreferences: true),
    iOptions : IOSOptions( accessibility: KeychainAccessibility.first_unlock),
  );

  Future <void> saveToken({
    required String accessToken,
    required String refreshToken,
  }) async{
    await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
    await _storage.write(key: AppConstants.refreshTokenkey, value: refreshToken);
  } 

  Future<String?> getToken()async{
    return await _storage.read(key: AppConstants.accessTokenKey); 
  }

  Future<String?> getRefreshToken()async{
    return await _storage.read(key: AppConstants.refreshTokenkey);
  }

  Future<void> clearToken()async{
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenkey);
  }
  
  Future<bool> hasToken()async{
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    return token!= null && token.isNotEmpty;
  }
}