import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yappsters/Features/auth/data/repository/improved_auth_functions.dart';
import 'package:yappsters/Features/auth/presentation/pages/enhanced_email_verification_page.dart';
import 'package:yappsters/Features/auth/presentation/pages/signup_page.dart';
import 'package:yappsters/core/constants/routes.dart';
import 'package:yappsters/core/theme/app_pallete.dart';
import 'package:yappsters/widgets/enhanced_auth_field.dart';
import 'package:yappsters/widgets/auth_gradient_button.dart';

class ImprovedLoginPage extends StatefulWidget {
  const ImprovedLoginPage({super.key});

  @override
  State<ImprovedLoginPage> createState() => _ImprovedLoginPageState();
}

class _ImprovedLoginPageState extends State<ImprovedLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ImprovedAuthFunctions _auth = ImprovedAuthFunctions();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await _auth.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted && userCredential != null) {
        final user = userCredential.user;
        if (user != null && !user.emailVerified) {
          // Redirect to email verification
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const EnhancedEmailVerificationPage(),
            ),
          );
        } else {
          // Navigate to main app
          Navigator.pushReplacementNamed(context, navBar);
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await _auth.signInWithGoogle();

      if (mounted && userCredential != null) {
        final user = userCredential.user;
        if (user != null) {
          // Check if user needs to set username for Google account
          final profile = await _auth.getUserProfile();
          if (profile?['username'] == null) {
            // Navigate to username setup (you can create this page if needed)
            Navigator.pushReplacementNamed(context, navBar);
          } else {
            Navigator.pushReplacementNamed(context, navBar);
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getGoogleErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Google sign-in failed. Please try again.';
      });
    } finally {
      setState(() => _isGoogleLoading = false);
    }
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many login attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  String _getGoogleErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'sign-in-canceled':
        return 'Google sign-in was canceled.';
      case 'network-error':
        return 'Network error. Please check your connection.';
      case 'sign-in-failed':
        return 'Google sign-in failed. Please try again.';
      case 'account-exists-with-different-credential':
        return 'An account exists with this email but different sign-in method.';
      case 'operation-not-allowed':
        return 'Google sign-in is not enabled. Contact support.';
      default:
        return 'Google sign-in error. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Welcome back section
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppPallete.gradient1,
                              AppPallete.gradient2
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: AppPallete.whiteColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppPallete.whiteColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to continue chatting',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppPallete.greyColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Email field
                const Text(
                  'Email',
                  style: TextStyle(
                    color: AppPallete.whiteColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                EnhancedAuthField(
                  hintText: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Password field
                const Text(
                  'Password',
                  style: TextStyle(
                    color: AppPallete.whiteColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                EnhancedAuthField(
                  hintText: 'Enter your password',
                  controller: _passwordController,
                  isObscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppPallete.greyColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Forgot password link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement forgot password
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Forgot password feature coming soon!'),
                          backgroundColor: AppPallete.gradient1,
                        ),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: AppPallete.gradient1),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppPallete.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppPallete.errorColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppPallete.errorColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style:
                                const TextStyle(color: AppPallete.errorColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Sign in button
                AuthGradientButton(
                  buttonText: _isLoading ? 'Signing In...' : 'Sign In',
                  onPressed: _isLoading ? () {} : _signIn,
                ),

                const SizedBox(height: 20),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: AppPallete.borderColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or continue with',
                        style: const TextStyle(color: AppPallete.greyColor),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: AppPallete.borderColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Google Sign In button
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppPallete.whiteColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppPallete.borderColor),
                  ),
                  child: Material(
                    color: AppPallete.transparentColor,
                    child: InkWell(
                      onTap: (_isGoogleLoading || _isLoading)
                          ? null
                          : _signInWithGoogle,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isGoogleLoading) ...[
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppPallete.gradient1,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ] else ...[
                              Image.network(
                                'https://developers.google.com/identity/images/g-logo.png',
                                width: 20,
                                height: 20,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.g_mobiledata,
                                    size: 24,
                                    color: AppPallete.gradient1,
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                            ],
                            Text(
                              _isGoogleLoading
                                  ? 'Signing in...'
                                  : 'Continue with Google',
                              style: const TextStyle(
                                color: AppPallete.backgroundColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Don\'t have an account? ',
                      style: TextStyle(color: AppPallete.greyColor),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: AppPallete.gradient1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
