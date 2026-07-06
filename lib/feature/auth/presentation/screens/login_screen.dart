import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test/feature/auth/presentation/bloc/auth_event.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final  _usernameController = TextEditingController();
  final  _passwordController = TextEditingController();

  // @override
  // void initState() {
  //   super.initState();
  //   usernameController = TextEditingController(text: "");
  //   passwordController = TextEditingController(text: "");
  // }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: ( context, state) {
            if(state is AuthSuccess){
              Navigator.pushReplacementNamed(context, '/bookings');
            }else if(state is AuthFailureState){
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );              
            }
            },
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 24),
                isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: (){
                      context.read<AuthBloc>().add(
                        LoginRequested(
                          username: _usernameController.text.trim(), 
                          password: _passwordController.text)
                      );
                  }, child: const Text('Login')),
              ],
            );


           }, 
          
          )
        
        // Column(
        //   children: [
        //     TextField(
        //       maxLines: 1,
        //       decoration: InputDecoration(labelText: 'Enter Username'),
        //       controller: usernameController,
        //     ),
        //     TextField(
        //       maxLines: 1,
        //       decoration: InputDecoration(labelText: 'Enter password'),
        //       controller: passwordController,
        //       obscureText: true,
        //     ),
        //     ElevatedButton(onPressed: (){}, child: Text("Log in"),),
        //   ],
        // ),
      ),
    );
  }
}
