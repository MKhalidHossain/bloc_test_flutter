import 'package:test/core/utils/failure.dart';


// class AuthUsecase {
//   final AuthRepository authRepository;

//   AuthUsecase({required this.authRepository});

//   Future<UserModel> login(String username, String password) async {
//     return await authRepository.login(username, password);
//   }
// }


abstract class AuthUsecase<Type,Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {
  const NoParams();
}