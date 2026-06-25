import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test/core/constants/api_constants.dart';

class RefreshTokenInterceptor extends Interceptor {
  final Dio dio;
  final FlutterSecureStorage secureStorage;

  RefreshTokenInterceptor(this.dio, this.secureStorage);

  bool _isRefreshing = false;
  final List<Completer<void>> _pendingRequests = [];

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshCall = err.requestOptions.path == ApiConstants.refresh;
  }
}
