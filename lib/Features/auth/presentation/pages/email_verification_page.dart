import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yappsters/Features/auth/data/repository/auth_functions.dart';
import 'package:yappsters/core/theme/app_pallete.dart';
import 'package:yappsters/core/constants/routes.dart';
import 'package:yappsters/widgets/auth_gradient_button.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final AuthFunctions _auth = AuthFunctions();
  bool isLoading = false;
  bool isCheckingVerification = false;
  String? errorMessage;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.getCurrentUser();
    _checkEmailVerificationStatus();
  }

  Future<void> _checkEmailVerificationStatus() async {
    if (currentUser != null) {
      await _auth.reloadUser();
      if (_auth.isEmailVerified() && mounted) {
        Navigator.pushReplacementNamed(context, navBar);
      }
    }
  }

  Future<void> _sendEmailVerification() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _auth.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Please check your inbox.'),
            backgroundColor: AppPallete.gradient1,
          ),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error sending verification email: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _checkVerificationStatus() async {
    setState(() {
      isCheckingVerification = true;
      errorMessage = null;
    });

    try {
      await _auth.reloadUser();

      if (_auth.isEmailVerified()) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, navBar);
        }
      } else {
        setState(() {
          errorMessage =
              'Email not yet verified. Please check your email and click the verification link.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error checking verification status: $e';
      });
    } finally {
      setState(() => isCheckingVerification = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppPallete.transparentColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              _auth.signOut();
              Navigator.pushNamedAndRemoveUntil(
                  context, loginRoute, (route) => false);
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppPallete.errorColor),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppPallete.gradient1.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppPallete.gradient1, width: 2),
              ),
              child: const Icon(
                Icons.email_outlined,
                size: 60,
                color: AppPallete.gradient1,
              ),
            ),

            const SizedBox(height: 30),

            // Title
            const Text(
              'Verify Your Email',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppPallete.whiteColor,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              'We\'ve sent a verification email to:',
              style: const TextStyle(
                fontSize: 16,
                color: AppPallete.greyColor,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              currentUser?.email ?? '',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppPallete.whiteColor,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            const Text(
              'Please check your email and click the verification link to continue.',
              style: TextStyle(
                fontSize: 14,
                color: AppPallete.greyColor,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Check verification button
            AuthGradientButton(
              buttonText: isCheckingVerification
                  ? 'Checking...'
                  : 'I\'ve Verified My Email',
              onPressed:
                  isCheckingVerification ? () {} : _checkVerificationStatus,
            ),

            const SizedBox(height: 16),

            // Resend email button
            OutlinedButton(
              onPressed: isLoading ? null : _sendEmailVerification,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppPallete.gradient1),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppPallete.gradient1,
                      ),
                    )
                  : const Text(
                      'Resend Verification Email',
                      style: TextStyle(color: AppPallete.gradient1),
                    ),
            ),

            if (errorMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppPallete.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppPallete.errorColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: AppPallete.errorColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: AppPallete.errorColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),

            // Help text
            const Text(
              'Didn\'t receive the email? Check your spam folder or try resending.',
              style: TextStyle(
                fontSize: 12,
                color: AppPallete.greyColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
