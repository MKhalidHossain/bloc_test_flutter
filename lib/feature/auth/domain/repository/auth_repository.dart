import 'package:dartz/dartz.dart';
import 'package:test/core/utils/failure.dart';

import '../entitys/user_entities.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login(String userName, String password);
  Future<Either<Failure, void>> logout(); 
}
