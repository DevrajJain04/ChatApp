import 'package:flutter/material.dart';
import 'package:yappsters/Features/auth/data/repository/auth_functions.dart';
import 'package:yappsters/core/constants/routes.dart';
import 'package:yappsters/widgets/auth_field.dart';
import 'package:yappsters/widgets/auth_gradient_button.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  AuthFunctions _authFunctions = AuthFunctions();
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.yellowAccent,
              ),
            ),
            const Spacer(),
            AuthField(hintText: 'Username', controller: _usernameController),
            const Spacer(),
            AuthField(
              hintText: 'Email',
              controller: _emailController,
            ),
            const Spacer(),
            AuthField(
              hintText: 'Password',
              controller: _passwordController,
              isObscureText: true,
            ),
            const Spacer(),
            AuthGradientButton(
              buttonText: 'Sign Up',
              onPressed: () async {
                await _authFunctions.signUp(
                    email: _emailController.text.trim().toLowerCase(),
                    password: _passwordController.text.trim(),
                    userName: _usernameController.text.trim());
                Navigator.of(context).pushReplacementNamed(navBar);
              },
            ),
          ],
        ),
      ),
    );
  }
}
