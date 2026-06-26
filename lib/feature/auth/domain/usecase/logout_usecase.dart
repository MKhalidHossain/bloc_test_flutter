import 'package:dartz/dartz.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/failure.dart';
import '../repository/auth_repository.dart';


class LogoutUsecase implements UseCase<void, NoParams> {
  final AuthRepository repository;

  LogoutUsecase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.logout();
  }

}

