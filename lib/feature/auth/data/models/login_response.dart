import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final String expiresIn;
  final String user;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'],
      refreshToken: json["refresh_token"],
      expiresIn: json["expires_in"],
      user: json["user"],
    );
  }

  // factory LoginResponse.fromJson(Map<String, dynamic> json) =>
  //     _$LoginResponseModelToJson(json);

  // Map<String, dynamic> toJson() => _$LoginResponseModelToJson(this);
}
