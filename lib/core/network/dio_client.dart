

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:test/core/network/interceptors/auth_interceptor.dart';
import 'package:test/core/network/interceptors/logging_interceptor.dart';
import 'package:test/core/network/interceptors/refresh_token_interceptor.dart';
import '../Storage/secure_storage_service.dart';
import '../constants/api_constants.dart';


class DioClient {
  final Dio dio;

  DioClient(this.dio, SecureStorageService secureStorageService){
    dio.options = BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) =>
        status != null && status <500 && status != 401,
    );

    dio.interceptors.addAll([
      AuthInterceptor(secureStorageService),
      if (kDebugMode) LoggingInterceptor(),
      RefreshTokenInterceptor(dio, secureStorageService),
    ]);
  }
}

