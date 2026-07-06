import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test/core/Storage/secure_storage_service.dart';
import 'package:test/core/network/auth_api_service.dart';
import 'package:test/core/network/dio_client.dart';
import 'package:test/feature/auth/data/datasource/auth_remote_data_source_impl.dart';
import 'package:test/feature/auth/data/repository/auth_repository_impl.dart';
import 'package:test/feature/auth/domain/usecase/get_cached_user_usecase.dart';
import 'package:test/feature/auth/domain/usecase/login_usecase.dart';
import 'package:test/feature/auth/domain/usecase/logout_usecase.dart';
import 'package:test/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:test/feature/auth/presentation/screens/login_screen.dart';

void main() {
  final secureStorageService = SecureStorageService();
  final dioClient = DioClient(Dio(), secureStorageService);
  final apiService = AuthApiService(dioClient.dio);

  final repository = AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(apiService: apiService),
    secureStorageService: secureStorageService,
  );

  runApp(
    MyApp(
      authBloc: AuthBloc(
        loginUsecase: LoginUsecase(repository),
        logoutUsecase: LogoutUsecase(repository),
        getCachedUserUsecase: GetCachedUserUsecase(repository),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.authBloc});

  final AuthBloc authBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => authBloc,
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
