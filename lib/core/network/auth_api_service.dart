
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:test/feature/auth/data/models/auth_request_model.dart';
import 'package:test/feature/auth/data/models/auth_response_model.dart';





// @RestApi(baseUrl: "http://localhost:8080")
@RestApi()

abstract class AuthApiService {
  factory AuthApiService (Dio dio, {String baseUrl}) = _AuthApiService;

  @POST("/auth/login")
  // Future<UserModel> logIn(String username, String password);
  Future<AUthResponseModel> logIn(
    @Body() LoginRequest request,
  );

  Future<AUthResponseModel> refresh(
    @Body() Map<String, dynamic> body
  );

}