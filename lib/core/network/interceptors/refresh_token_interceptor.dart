import 'dart:async';

import 'package:dio/dio.dart';
import '../../Storage/secure_storage_service.dart';
import '../../constants/api_constants.dart';


class RefreshTokenInterceptor extends Interceptor {
  final Dio dio;
  final SecureStorageService secureStorageService;

  RefreshTokenInterceptor(this.dio, this.secureStorageService);

  bool _isRefreshing = false;
  // Completers for requests that 401'd while a refresh is already in flight.
  // They resolve with `true` once the new token is ready, or `false` if the
  // refresh failed (so the request can fail fast instead of retrying blindly).
  final List<Completer<bool>> _pendingRequests = [];

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshCall = err.requestOptions.path == ApiConstants.refresh;

    // Only attempt a refresh for 401s on non-refresh endpoints. Anything else
    // (including a failing refresh call itself) propagates as-is.
    if (!isUnauthorized || isRefreshCall) {
      handler.next(err);
      return;
    }

    // A refresh is already running — queue this request behind it.
    if (_isRefreshing) {
      final completer = Completer<bool>();
      _pendingRequests.add(completer);
      final refreshed = await completer.future;
      if (refreshed) {
        return _retry(err.requestOptions, handler);
      }
      return _failAuth(err, handler);
    }

    _isRefreshing = true;
    try {
      final refreshToken = await secureStorageService.getRefreshToken();

      if (refreshToken == null) {
        _resolvePending(false);
        return _failAuth(err, handler);
      }

      // A dedicated Dio with no interceptors so the refresh call can't recurse.
      final refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      final response = await refreshDio.post(
        ApiConstants.refresh,
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = response.data['access_token'] as String;
      final newRefreshToken = response.data['refresh_token'] as String;

      await secureStorageService.saveToken(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      _resolvePending(true);
      return _retry(err.requestOptions, handler);
    } catch (e) {
      _resolvePending(false);
      return _failAuth(err, handler);
    } finally {
      _isRefreshing = false;
    }
  }

  void _resolvePending(bool refreshed) {
    for (final c in _pendingRequests) {
      if (!c.isCompleted) c.complete(refreshed);
    }
    _pendingRequests.clear();
  }

  Future<void> _retry(
    RequestOptions requestOptions,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      final newToken = await secureStorageService.getToken();
      requestOptions.headers['Authorization'] = 'Bearer $newToken';
      final response = await dio.fetch(requestOptions);
      handler.resolve(response);
    } catch (e) {
      handler.reject(
        e is DioException
            ? e
            : DioException(requestOptions: requestOptions, error: e),
      );
    }
  }

  Future<void> _failAuth(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    await secureStorageService.clearToken();
    handler.next(err);
  }
}
