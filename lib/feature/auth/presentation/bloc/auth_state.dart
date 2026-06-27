import 'package:equatable/equatable.dart';
import 'package:test/feature/auth/domain/entitys/user_entities.dart';

abstract class AuthState extends Equatable{
  const AuthState();

  @override
  List<Object?> get props =>[];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final UserEntity user;
  const AuthSuccess(this.user);

  @override
  List<Object?> get props => [user];
}


class AuthFailureState extends AuthState {
  final String message;
  const AuthFailureState(this.message);

  @override
  List<Object?> get props => [message];
}

class Unauthenticated extends AuthState {}