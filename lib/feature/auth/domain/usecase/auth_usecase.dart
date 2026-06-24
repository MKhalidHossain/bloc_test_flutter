import 'package:test/feature/auth/data/models/user_model.dart';
import 'package:test/feature/auth/domain/repository/auth_repository.dart';

class AuthUsecase {
  final AuthRepository authRepository;

  AuthUsecase({required this.authRepository});

  Future<UserModel> login(String username, String password) async {
    return await authRepository.login(username, password);
  }
}
