// class UserEntities {
//   final String id;
//   final String serviceId;
//   final String bookingTime;
//   final String doctorId;
//   final String status;
//   final String createdAt;

//   UserEntities({
//     required this.id,
//     required this.serviceId,
//     required this.bookingTime,
//     required this.doctorId,
//     required this.status,
//     required this.createdAt,
//   });
// }


class UserEntity {
  final String id;
  final String username;
  final String name;

  const UserEntity({
    required this.id,
    required this.username,
    required this.name,
  });
}