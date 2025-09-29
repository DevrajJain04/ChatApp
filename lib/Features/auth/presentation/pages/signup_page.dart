import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:yappsters/Features/auth/data/repository/auth_functions.dart';
import 'package:yappsters/core/constants/routes.dart';
import 'package:yappsters/core/theme/app_pallete.dart';
import 'package:yappsters/widgets/auth_field.dart';
import 'package:yappsters/widgets/auth_gradient_button.dart';
import 'email_verification_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final AuthFunctions _authFunctions = AuthFunctions();
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
      backgroundColor: AppPallete.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppPallete.transparentColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppPallete.whiteColor),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppPallete.whiteColor,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Join our community and start chatting',
              style: TextStyle(
                fontSize: 16,
                color: AppPallete.greyColor,
              ),
            ),
            const SizedBox(height: 40),
            AuthField(hintText: 'Username', controller: _usernameController),
            const SizedBox(height: 16),
            AuthField(
              hintText: 'Email',
              controller: _emailController,
            ),
            const SizedBox(height: 16),
            AuthField(
              hintText: 'Password',
              controller: _passwordController,
              isObscureText: true,
            ),
            const SizedBox(height: 30),
            AuthGradientButton(
              buttonText: 'Sign Up',
              onPressed: () async {
                try {
                  await _authFunctions.signUp(
                      email: _emailController.text.trim().toLowerCase(),
                      password: _passwordController.text.trim(),
                      userName: _usernameController.text.trim());

                  // Send email verification after successful signup
                  await _authFunctions.sendEmailVerification();

                  if (!mounted) return;

                  // Navigate to email verification page
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (context) => const EmailVerificationPage()),
                  );
                } on FirebaseException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.message ?? 'Sign up failed'),
                      backgroundColor: AppPallete.errorColor,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sign up failed'),
                      backgroundColor: AppPallete.errorColor,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(color: AppPallete.greyColor),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, loginRoute),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(color: AppPallete.gradient1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
