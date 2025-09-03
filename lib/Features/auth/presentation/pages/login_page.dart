import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:yappsters/core/constants/routes.dart';
import 'package:yappsters/widgets/auth_field.dart';
import 'package:yappsters/widgets/auth_gradient_button.dart';

import '../../data/repository/auth_functions.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({super.key});

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final _auth = AuthFunctions();
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Log In',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.yellowAccent,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            AuthField(
              hintText: 'Email',
              controller: _emailController,
            ),
            const SizedBox(height: 20),
            AuthField(
              hintText: 'Password',
              controller: _passwordController,
            ),
            const Spacer(),
            AuthGradientButton(
              buttonText: 'Log In',
              onPressed: () async {
                await _auth.signIn(
                    email: _emailController.text.trim().toLowerCase(),
                    password: _passwordController.text.trim());
                Navigator.of(context).pushReplacementNamed(navBar);
              },
            ),
            const Spacer(),
            AuthGradientButton(
                buttonText: 'Not an existing user ? Sign Up Now',
                onPressed: () {
                  Navigator.of(context).pushNamed(signupRoute);
                }),
            const Spacer(),
            AuthGradientButton(
                buttonText: 'GoogleSignIN',
                onPressed: () async {
                  // User? currentUser = FirebaseAuth.instance.currentUser;
                  // if (currentUser == null) {}
                  try {
                    UserCredential? user = await _auth.signInWithGoogle(
                        googleInstance: _googleSignIn,
                        username: _emailController.text.trim());
                    if (user != null) {
                      Navigator.of(context).pushReplacementNamed(navBar);
                    }
                  } catch (e) {
                    print(e.toString());
                  }
                }),
          ],
        ),
      ),
    );
  }
}
