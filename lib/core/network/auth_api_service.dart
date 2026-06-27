
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:test/core/constants/api_constants.dart';
import 'package:test/feature/auth/data/models/login_request_model.dart';
import 'package:test/feature/auth/data/models/auth_response_model.dart';

part 'auth_api_service.g.dart';
// @RestApi(baseUrl: "http://localhost:8080")
@RestApi()

abstract class AuthApiService {
  factory AuthApiService (Dio dio, {String baseUrl}) = _AuthApiService;

  @POST(ApiConstants.logIn)
  Future<AuthResponseModel> logIn(
    @Body() LoginRequest request,
  );

  @POST(ApiConstants.refresh)
  Future<AuthResponseModel> refresh(
    @Body() Map<String, dynamic> body
  );

}