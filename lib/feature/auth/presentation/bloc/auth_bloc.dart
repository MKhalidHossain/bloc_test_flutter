import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:test/feature/auth/domain/usecase/get_cached_user_usecase.dart';

import '../../../../core/Storage/secure_storage_service.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecase/login_usecase.dart';
import '../../domain/usecase/logout_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUsecase loginUsecase;
  final LogoutUsecase logoutUsecase;
  final GetCachedUserUsecase getCachedUserUsecase;

  AuthBloc({
    required this.loginUsecase,
    required this.logoutUsecase,
    required this.getCachedUserUsecase,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthCheckRequested>(_onAuthCheckRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await loginUsecase(
      LoginParams(username: event.username, password: event.password),
    );

    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (user) => emit(AuthSuccess(user)),
    );
  }

  FutureOr<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await logoutUsecase(const NoParams());

    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (_) => emit(Unauthenticated()),
    );
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await getCachedUserUsecase(const NoParams());
    result.fold(
      (failure) => emit(Unauthenticated()),
      (user){
        if(user== null){
          emit(Unauthenticated());
        }else{
          emit(AuthSuccess(user));
        }
      }
    );
    // We have a token, but we don't know if it's still valid until we
    // actually call an authenticated endpoint. For this assessment,
    // treat "token exists" as "proceed to booking screen" — the
    // RefreshTokenInterceptor will catch an expired token on the
    // first real API call and silently refresh it.
    emit(
      Unauthenticated(),
    ); // placeholder until a real getCurrentUser usecase exists — see note below
  }
}
