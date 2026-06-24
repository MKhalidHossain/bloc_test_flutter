import 'package:test/feature/auth/domain/entitys/user_entities.dart';

class UserModel {
  final String id;
  final String userName;
  final String accessToken;
  final String refreshToken;
  final String? serviceId;
  final String? bookingTime;
  final String? doctorId;
  final String? status;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.userName,
    required this.accessToken,
    required this.refreshToken,
    this.serviceId,
    this.bookingTime,
    this.doctorId,
     this.status,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      userName: json['username'],
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
    );
  }

  UserEntities toEntity() {
    return UserEntities(
      id: id,
      serviceId: serviceId ?? '',
      bookingTime: bookingTime ?? '',
      doctorId: doctorId ?? '',
      status: status ?? '',
      createdAt: createdAt ?? '',
    );
  }
}
