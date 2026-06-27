

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entitys/user_entities.dart';
import '../repository/auth_repository.dart';

class LoginUsecase implements UseCase<UserEntity,LoginParams>{
  final AuthRepository repository;

  LoginUsecase(this.repository);


  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) {
    return repository.login(params.username, params.password);
  }
  
}

class LoginParams extends Equatable{
  final String username;
  final String password;

  LoginParams({required this.username, required this.password});

  @override
  List<Object?> get props => [username, password];

}