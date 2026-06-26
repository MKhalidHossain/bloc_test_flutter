import 'dart:developer' as developer;
import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  static const _name = "DioClient from : LoggingInterceptor";
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log(
      '\n==== Request ==== \n${options.method} ${options.uri}' 
      '${options.data != null? '\n body : ${options.data}' : '' }',
      name: _name
    );
    if (options.data != null) developer.log('body: ${options.data}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    developer.log(
      '\n=== Response === \n${response.statusCode} ${response.data} ${response.requestOptions.uri} ',
      name: _name,
    );
    if (response.data != null) developer.log('Data: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log(
      '\n=== Error ===\n${err.response?.statusCode} ${err.requestOptions.uri} - ${err.response?.data ?? err.message}',
      name: _name,
      error: err.response?.data ?? err.message,
      stackTrace: err.stackTrace,
    );
    handler.next(err);
  }
}
