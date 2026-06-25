import 'package:json_annotation/json_annotation.dart';
import 'package:test/feature/auth/data/models/user_model.dart';

import '../../domain/entitys/user_entities.dart';

@JsonSerializable()
class AUthResponseModel {
  final String accessToken;
  final String refreshToken;
  final String expiresIn;
  final String tokenType;
  final UserModel? user;

  AUthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
    this.user,
  });

  factory AUthResponseModel.fromJson(Map<String, dynamic> json) {
    return AUthResponseModel(
      accessToken: json['access_token'],
      refreshToken: json["refresh_token"],
      expiresIn: json["expires_in"],
      tokenType: json["token_type"],
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  // factory LoginResponse.fromJson(Map<String, dynamic> json) =>
  //     _$LoginResponseModelToJson(json);

  // Map<String, dynamic> toJson() => _$LoginResponseModelToJson(this);
}

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    required super.name,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      name: json['name'] as String,
    );
  }
}
