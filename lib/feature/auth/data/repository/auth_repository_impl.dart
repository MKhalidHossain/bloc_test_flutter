import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/Storage/secure_storage_service.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entitys/user_entities.dart';
import '../../domain/repository/auth_repository.dart';
import '../datasource/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService secureStorageService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorageService,
  });

  @override
  Future<Either<Failure, UserEntity>> login(
    String userName,
    String password,
  ) async {
    try {
      final authResponse = await remoteDataSource.login(userName, password);

      await secureStorageService.saveToken(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );

      if (authResponse.user == null) {
        return const Left(
          ServerFailure('Login succeeded but no user data returned '),
        );
      }

      await secureStorageService.saveUser(
        id: authResponse.user!.id,
        username: authResponse.user!.username,
        name: authResponse.user!.name,
      );

      return Right(authResponse.user!);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map && data['error'] != null)
          ? data['error'].toString()
          : 'Login Faild';
      return Left(ServerFailure(message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await secureStorageService.clearToken();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCachedUser() async {
    try {
      final cached = await secureStorageService.getCachedUser();
      if (cached == null) return const Right(null);

      return Right(
        UserEntity(
          id: cached['id']!,
          username: cached['username']!,
          name: cached['name']!,
        ),
      );
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
