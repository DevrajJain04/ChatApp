import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yappsters/Features/auth/data/repository/auth_functions.dart';
import 'package:yappsters/core/theme/app_pallete.dart';
import 'package:yappsters/core/constants/routes.dart';
import 'package:yappsters/widgets/auth_gradient_button.dart';

class EnhancedEmailVerificationPage extends StatefulWidget {
  const EnhancedEmailVerificationPage({super.key});

  @override
  State<EnhancedEmailVerificationPage> createState() =>
      _EnhancedEmailVerificationPageState();
}

class _EnhancedEmailVerificationPageState
    extends State<EnhancedEmailVerificationPage> {
  final _auth = AuthFunctions();

  bool isLoading = false;
  bool isChecking = false;
  String? errorMessage;
  User? currentUser;

  // Timer related
  Timer? _resendTimer;
  int _resendCountdown = 0;
  bool _canResend = true;

  // Auto-check timer
  Timer? _autoCheckTimer;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.getCurrentUser();
    _startAutoCheck();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  void _startAutoCheck() {
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkVerificationStatusSilently();
    });
  }

  Future<void> _checkVerificationStatusSilently() async {
    try {
      await _auth.reloadUser();
      if (_auth.isEmailVerified() && mounted) {
        _autoCheckTimer?.cancel();
        Navigator.pushReplacementNamed(context, navBar);
      }
    } catch (e) {
      // Silent fail for auto-check
    }
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60; // 60 seconds cooldown
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _sendVerificationEmail() async {
    if (!_canResend) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _auth.sendEmailVerification();
      _startResendTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Check your inbox.'),
            backgroundColor: AppPallete.gradient1,
          ),
        );
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('too-many-requests')) {
        errorMsg =
            'Rate limit exceeded. Please wait before requesting another email.';
        _startResendTimer(); // Start cooldown even on error
      }
      setState(() => errorMessage = errorMsg);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _checkVerification() async {
    setState(() {
      isChecking = true;
      errorMessage = null;
    });

    try {
      await _auth.reloadUser();

      if (_auth.isEmailVerified()) {
        if (mounted) {
          _autoCheckTimer?.cancel();
          Navigator.pushReplacementNamed(context, navBar);
        }
      } else {
        setState(() =>
            errorMessage = 'Email not verified yet. Please check your email.');
      }
    } catch (e) {
      setState(() => errorMessage = 'Error checking verification: $e');
    } finally {
      setState(() => isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppPallete.transparentColor,
        elevation: 0,
        title: const Text('Verify Email',
            style: TextStyle(color: AppPallete.whiteColor)),
        actions: [
          TextButton(
            onPressed: () {
              _auth.signOut();
              Navigator.pushNamedAndRemoveUntil(
                  context, loginRoute, (route) => false);
            },
            child: const Text('Sign Out',
                style: TextStyle(color: AppPallete.errorColor)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated email icon
            TweenAnimationBuilder(
              duration: const Duration(seconds: 2),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: 0.8 + (value * 0.2),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color:
                          AppPallete.gradient1.withOpacity(0.1 + (value * 0.1)),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppPallete.gradient1, width: 2),
                    ),
                    child: const Icon(Icons.email_outlined,
                        size: 60, color: AppPallete.gradient1),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            const Text(
              'Check Your Email',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppPallete.whiteColor,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              'We sent a verification link to:',
              style: const TextStyle(fontSize: 16, color: AppPallete.greyColor),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppPallete.borderColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                currentUser?.email ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppPallete.whiteColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            // Auto-checking indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPallete.gradient1.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppPallete.gradient1.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppPallete.gradient1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Checking verification status...',
                    style: TextStyle(color: AppPallete.gradient1, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            AuthGradientButton(
              buttonText:
                  isChecking ? 'Checking...' : 'I\'ve Verified My Email',
              onPressed: isChecking ? () {} : _checkVerification,
            ),

            const SizedBox(height: 16),

            // Resend button with timer
            OutlinedButton(
              onPressed:
                  (_canResend && !isLoading) ? _sendVerificationEmail : null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color:
                      _canResend ? AppPallete.gradient1 : AppPallete.greyColor,
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppPallete.gradient1),
                    )
                  : Text(
                      _canResend
                          ? 'Resend Verification Email'
                          : 'Resend in ${_resendCountdown}s',
                      style: TextStyle(
                        color: _canResend
                            ? AppPallete.gradient1
                            : AppPallete.greyColor,
                      ),
                    ),
            ),

            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppPallete.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppPallete.errorColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_outlined,
                        color: AppPallete.errorColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(errorMessage!,
                          style: const TextStyle(color: AppPallete.errorColor)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Help section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppPallete.borderColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.help_outline,
                          color: AppPallete.whiteColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Need help?',
                        style: TextStyle(
                          color: AppPallete.whiteColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Check your spam/junk folder\n• Wait a few minutes for the email to arrive\n• Make sure you clicked the verification link\n• Try signing in again after verification',
                    style: TextStyle(color: AppPallete.greyColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
