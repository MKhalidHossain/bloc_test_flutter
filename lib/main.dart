import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/services/connectivity_service.dart';
import 'feature/auth/presentation/bloc/auth_bloc.dart';
import 'feature/auth/presentation/bloc/auth_event.dart';
import 'feature/auth/presentation/bloc/auth_state.dart';
import 'feature/auth/presentation/screens/login_screen.dart';
import 'feature/booking/presentation/bloc/booking_bloc.dart';
import 'feature/booking/presentation/screens/booking_list_screen.dart';
import 'feature/booking/presentation/sync/sync_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested()),
        ),
        BlocProvider(create: (_) => sl<BookingBloc>()),
        BlocProvider(create: (_) => sl<SyncBloc>()),
      ],
      child: RepositoryProvider.value(
        value: sl<ConnectivityService>(),
        child: MaterialApp(
          title: 'Appointments',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const AuthGate(),
        ),
      ),
    );
  }
}

/// Decides between the login screen and the booking screen based on auth state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthSuccess) return const BookingListScreen();
        if (state is AuthInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Unauthenticated / AuthLoading / AuthFailureState -> login screen
        // (the screen renders its own loading + error feedback).
        return const LoginScreen();
      },
    );
  }
}
