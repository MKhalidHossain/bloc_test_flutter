import 'package:dio/dio.dart';
import 'package:test/core/Storage/secure_storage_service.dart';
import 'package:flutter/material.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final Dio _dio;
  final VoidCallback? onAuthFailed;

  AuthInterceptor({
    required SecureStorageService storage,
    required Dio dio,
    required this.onAuthFailed,
  }) : _storage = storage,
       _dio = dio;

  bool _isRefreshing = false;

  final List<RequestOptions> _pendingRequests = [];

  void onRequest
  
}
