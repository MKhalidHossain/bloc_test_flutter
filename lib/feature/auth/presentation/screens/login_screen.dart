import 'package:flutter/material.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController usernameController;
  late final TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(text: "");
    passwordController = TextEditingController(text: "");
  }

  @override
  void dispose() {
    super.dispose();
    usernameController;
    passwordController;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("please Enter your usernae and password")),

      body: Column(
        children: [
          TextField(
            maxLines: 1,
            decoration: InputDecoration(labelText: 'Enter Username'),
            controller: usernameController,
          ),
          TextField(
            maxLines: 1,
            decoration: InputDecoration(labelText: 'Enter password'),
            controller: passwordController,
            obscureText: true,
          ),
          ElevatedButton(onPressed: (){}, child: Text("Log in"),),
        ],
      ),
    );
  }
}
