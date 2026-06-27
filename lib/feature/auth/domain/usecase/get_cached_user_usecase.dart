

import 'package:dartz/dartz.dart';
import 'package:test/core/error/failure.dart';
import 'package:test/core/usecase/usecase.dart';
import 'package:test/feature/auth/domain/entitys/user_entities.dart';
import 'package:test/feature/auth/domain/repository/auth_repository.dart';

class GetCachedUserUsecase implements UseCase<UserEntity?,NoParams>{
  final AuthRepository repository;

  GetCachedUserUsecase(this.repository);

  @override
  Future<Either<Failure, UserEntity?>> call(NoParams params) {
    return repository.getCachedUser();
  }
}