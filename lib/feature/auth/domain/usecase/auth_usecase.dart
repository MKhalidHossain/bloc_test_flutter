import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';

abstract class AuthUsecase<Type,Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {
  const NoParams();
}