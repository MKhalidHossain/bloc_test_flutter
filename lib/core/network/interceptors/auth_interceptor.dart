import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../constants/api_constants.dart';
import '../../constants/app_constants.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage secureStorage;
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
      final token = await secureStorage.read(key: AppConstants.accessTokenKey);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}
