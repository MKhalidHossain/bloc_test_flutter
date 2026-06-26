import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/Storage/secure_storage_service.dart';
import '../../../../core/utils/failure.dart';
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
  Future<Either<Failure, UserEntity>> login(String userName, String password,) async{
    try{
      final authResponse = await remoteDataSource.login(userName, password);

      await secureStorageService.saveToken(accessToken: authResponse.accessToken,
       refreshToken: authResponse.refreshToken);

       if (authResponse.user == null) {
        return const Left(ServerFailure('Login succeeded but no user data returned '),
        );
       }

       return Right(authResponse.user!);
       
    } on DioException catch (e){ 
      final data = e.response?.data;
      // final message = (data is Map && data['error'] != null) ? 

    }
  }
  
  @override
  Future<Either<Failure, void>> logout() {
    // TODO: implement logout
    throw UnimplementedError();
  }


}
