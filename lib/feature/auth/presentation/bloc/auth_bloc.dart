import 'package:bloc/bloc.dart';
import 'package:test/feature/auth/domain/usecase/logout_usecase.dart';

import '../../domain/usecase/login_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState>{
  final LoginUsecase loginUsecase;
  final LogoutUsecase logoutUsecase;

  AuthBloc({required this.loginUsecase, required this.logoutUsecase}) : ;
}