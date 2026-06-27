import 'package:test/core/network/auth_api_service.dart';
import 'package:test/feature/auth/data/models/login_request_model.dart';
import 'package:test/feature/auth/data/models/auth_response_model.dart';
import 'auth_remote_data_source.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final AuthApiService apiService;

  AuthRemoteDataSourceImpl({required this.apiService});

  @override
  Future<AuthResponseModel> login(String username, String password) async {
    return await apiService.logIn(
      LoginRequest(userName: username, password: password),
    );
  }
}
