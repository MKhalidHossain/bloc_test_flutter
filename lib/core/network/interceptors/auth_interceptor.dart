


import 'package:dio/dio.dart';

import '../../Storage/secure_storage_service.dart';
import '../../constants/api_constants.dart';


class AuthInterceptor extends Interceptor {
  final SecureStorageService secureStorage;
  // final Dio _dio;
  // final VoidCallback? onAuthFailed;

  AuthInterceptor(this.secureStorage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isAuthEndpoint =
        options.path == ApiConstants.logIn ||
        options.path == ApiConstants.refresh;

    if (!isAuthEndpoint) {
      final token = await secureStorage.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}
