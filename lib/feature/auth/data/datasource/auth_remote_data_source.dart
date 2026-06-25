

import 'package:test/feature/auth/data/models/auth_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<AUthResponseModel> login(String username, String password);
}

