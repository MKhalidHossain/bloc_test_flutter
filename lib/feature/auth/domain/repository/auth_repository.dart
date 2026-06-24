import 'package:test/feature/auth/data/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login(String userName, String password);
}
