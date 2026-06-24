
import 'package:test/core/network/api_service.dart';
import 'package:test/feature/auth/data/models/login_request.dart';
import '../models/user_model.dart';
import 'auth_data_source.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource{
  late UserApiService apiService;

  @override
  Future<UserModel> login(String username, String password) async{
    return await apiService.logIn();
  }
}