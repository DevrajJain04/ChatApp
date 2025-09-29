import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:yappsters/core/constants/routes.dart';
import 'package:yappsters/core/theme/app_pallete.dart';
import 'package:yappsters/widgets/auth_field.dart';
import 'package:yappsters/widgets/auth_gradient_button.dart';
import 'phone_auth_page.dart';
import 'email_verification_page.dart';

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
      backgroundColor: AppPallete.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppPallete.transparentColor,
        elevation: 0,
        title: const Text(
          'Log In',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppPallete.whiteColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
              isObscureText: true,
            ),
            const SizedBox(height: 20),
            AuthGradientButton(
              buttonText: 'Log In',
              onPressed: () async {
                try {
                  await _auth.signIn(
                      email: _emailController.text.trim().toLowerCase(),
                      password: _passwordController.text.trim());

                  // Check if email is verified
                  if (!_auth.isEmailVerified()) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => const EmailVerificationPage()),
                    );
                    return;
                  }

                  Navigator.of(context).pushReplacementNamed(navBar);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Login failed: $e'),
                      backgroundColor: AppPallete.errorColor,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            AuthGradientButton(
                buttonText: 'Not an existing user ? Sign Up Now',
                onPressed: () {
                  Navigator.of(context).pushNamed(signupRoute);
                }),

            const SizedBox(height: 30),

            // Divider
            Row(
              children: const [
                Expanded(child: Divider(color: AppPallete.greyColor)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(color: AppPallete.greyColor),
                  ),
                ),
                Expanded(child: Divider(color: AppPallete.greyColor)),
              ],
            ),

            const SizedBox(height: 20),

            // Phone Auth Button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const PhoneAuthPage()),
                );
              },
              icon: const Icon(Icons.phone, color: AppPallete.gradient2),
              label: const Text(
                'Sign in with Phone',
                style: TextStyle(color: AppPallete.gradient2),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppPallete.gradient2),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            const SizedBox(height: 12),

            // Google Sign In Button
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  UserCredential? user = await _auth.signInWithGoogle(
                      googleInstance: _googleSignIn);
                  if (user != null) {
                    // If user has no username yet, ask for one briefly
                    final doc = await FirebaseFirestore.instance
                        .collection('Users')
                        .doc(user.user!.uid)
                        .get();
                    final hasUsername =
                        (doc.data() ?? const {})['username'] is String;
                    if (!hasUsername) {
                      final uname = await _askUsername(context);
                      if (uname != null && uname.isNotEmpty) {
                        await _auth.setUsernameForCurrentUser(uname.trim());
                      }
                    }
                    Navigator.of(context).pushReplacementNamed(navBar);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Google Sign In failed: $e'),
                      backgroundColor: AppPallete.errorColor,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.g_mobiledata, color: AppPallete.gradient1),
              label: const Text(
                'Sign in with Google',
                style: TextStyle(color: AppPallete.gradient1),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppPallete.gradient1),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _askUsername(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Choose a username'),
            content: AuthField(hintText: 'username', controller: controller),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                  child: const Text('Save')),
            ],
          );
        });
  }
}
