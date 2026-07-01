import 'dart:async';
import 'package:bloc/bloc.dart';


import '../../../../core/usecase/usecase.dart';
import '../../domain/usecase/get_cached_user_usecase.dart';
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
      (failure) {
        // ignore: avoid_print
        print('LOGIN FAILED -> ${failure.runtimeType}: ${failure.message}');
        emit(AuthFailureState(failure.message));
      },
      (user) {
        // ignore: avoid_print
        print('LOGIN SUCCESS -> emitting AuthSuccess for ${user.username}');
        emit(AuthSuccess(user));
      },
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
    // We have a cached user (and token) -> proceed to the booking screen.
    // We don't validate the token here; the RefreshTokenInterceptor will catch
    // an expired token on the first real API call and silently refresh it.
    final result = await getCachedUserUsecase(const NoParams());
    result.fold(
      (failure) => emit(Unauthenticated()),
      (user) {
        if (user == null) {
          emit(Unauthenticated());
        } else {
          emit(AuthSuccess(user));
        }
      },
    );
  }
}
