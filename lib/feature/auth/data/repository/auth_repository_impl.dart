import 'package:test/core/network/auth_api_service.dart';
import 'package:test/feature/auth/domain/repository/auth_repository.dart';

import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApiService _apiService;

  AuthRepositoryImpl(this._apiService);

  @override
  Future<UserModel> login(String userName, String password) async {
    try {
      return await _apiService.logIn(
        userName, password);
    } catch (e) {
      throw Exception(e);
    }
  }
}
