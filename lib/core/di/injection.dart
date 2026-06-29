import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../feature/auth/data/datasource/auth_remote_data_source.dart';
import '../../feature/auth/data/datasource/auth_remote_data_source_impl.dart';
import '../../feature/auth/data/repository/auth_repository_impl.dart';
import '../../feature/auth/domain/repository/auth_repository.dart';
import '../../feature/auth/domain/usecase/get_cached_user_usecase.dart';
import '../../feature/auth/domain/usecase/login_usecase.dart';
import '../../feature/auth/domain/usecase/logout_usecase.dart';
import '../../feature/auth/presentation/bloc/auth_bloc.dart';
import '../../feature/booking/data/datasource/booking_api_service.dart';
import '../../feature/booking/data/datasource/booking_local_data_source.dart';
import '../../feature/booking/data/datasource/booking_remote_data_source.dart';
import '../../feature/booking/data/datasource/booking_remote_data_source_impl.dart';
import '../../feature/booking/data/repository/booking_repository_impl.dart';
import '../../feature/booking/domain/repository/booking_repository.dart';
import '../../feature/booking/domain/usecase/cancel_booking_usecase.dart';
import '../../feature/booking/domain/usecase/create_booking_usecase.dart';
import '../../feature/booking/domain/usecase/get_bookings_usecase.dart';
import '../../feature/booking/presentation/bloc/booking_bloc.dart';
import '../../feature/booking/presentation/sync/sync_bloc.dart';
import '../Storage/secure_storage_service.dart';
import '../database/app_database.dart';
import '../network/auth_api_service.dart';
import '../network/dio_client.dart';
import '../services/connectivity_service.dart';
import '../services/email_confirmation_service.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ---- Core / infrastructure -------------------------------------------------
  sl.registerLazySingleton(() => SecureStorageService());
  sl.registerLazySingleton(() => AppDatabase());
  sl.registerLazySingleton(() => ConnectivityService());
  sl.registerLazySingleton(() => EmailConfirmationService());

  // A single Dio configured with auth + refresh interceptors, shared by all APIs.
  final dio = Dio();
  DioClient(dio, sl<SecureStorageService>());
  sl.registerLazySingleton<Dio>(() => dio);

  sl.registerLazySingleton(() => AuthApiService(sl()));
  sl.registerLazySingleton(() => BookingApiService(sl()));

  // ---- Auth feature ----------------------------------------------------------
  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(apiService: sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        remoteDataSource: sl(),
        secureStorageService: sl(),
      ));
  sl.registerLazySingleton(() => LoginUsecase(sl()));
  sl.registerLazySingleton(() => LogoutUsecase(sl()));
  sl.registerLazySingleton(() => GetCachedUserUsecase(sl()));
  sl.registerFactory(() => AuthBloc(
        loginUsecase: sl(),
        logoutUsecase: sl(),
        getCachedUserUsecase: sl(),
      ));

  // ---- Booking feature -------------------------------------------------------
  sl.registerLazySingleton(() => BookingLocalDataSource(sl()));
  sl.registerLazySingleton<BookingRemoteDataSource>(
      () => BookingRemoteDataSourceImpl(apiService: sl()));
  sl.registerLazySingleton<BookingRepository>(() => BookingRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        connectivityService: sl(),
        emailService: sl(),
      ));
  sl.registerLazySingleton(() => GetBookingsUsecase(sl()));
  sl.registerLazySingleton(() => CreateBookingUsecase(sl()));
  sl.registerLazySingleton(() => CancelBookingUsecase(sl()));

  // The Sync Engine is a single source of truth → single shared instance.
  sl.registerLazySingleton(() => SyncBloc(
        localDataSource: sl(),
        remoteDataSource: sl(),
        connectivityService: sl(),
        emailService: sl(),
      ));
  sl.registerLazySingleton(() => BookingBloc(
        getBookings: sl(),
        createBooking: sl(),
        cancelBooking: sl(),
      ));
}
