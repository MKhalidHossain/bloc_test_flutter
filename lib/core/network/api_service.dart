
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:test/feature/auth/data/models/login_request.dart';
import 'package:test/feature/auth/data/models/user_model.dart';

part 'api_service.g.dart';


// @RestApi(baseUrl: "http://localhost:8080")
@RestApi()

abstract class UserApiService {
  factory UserApiService (Dio dio, {String baseUrl}) = _UserApiService;

  @POST("/auth/login")
  // Future<UserModel> logIn(String username, String password);
  Future<UserModel> logIn(
    @Body() LoginRequest request,
  );

}