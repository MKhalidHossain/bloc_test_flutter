import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entitys/user_entities.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login(String userName, String password);
  Future<Either<Failure, void>> logout(); 
}
