import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yappsters/Features/auth/data/repository/auth_functions.dart';
import 'package:yappsters/core/theme/app_pallete.dart';
import 'package:yappsters/core/constants/routes.dart';
import 'package:yappsters/widgets/auth_field.dart';
import 'package:yappsters/widgets/auth_gradient_button.dart';

class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({super.key});

  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final _auth = AuthFunctions();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool isLoading = false;
  bool otpSent = false;
  String? verificationId;
  String? errorMessage;

  void _showError(String message) {
    setState(() {
      errorMessage = message;
      isLoading = false;
    });
  }

  Future<void> _sendOTP() async {
    if (_phoneController.text.trim().isEmpty) {
      _showError('Please enter a valid phone number');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _phoneController.text.trim(),
        verificationCompleted: (credential) async {
          try {
            await _auth.signInWithPhoneCredential(credential);
            if (mounted) Navigator.pushReplacementNamed(context, navBar);
          } catch (e) {
            _showError('Auto-verification failed: ${e.toString()}');
          }
        },
        verificationFailed: (e) =>
            _showError('Verification failed: ${e.message}'),
        codeSent: (vId, resendToken) {
          setState(() {
            verificationId = vId;
            otpSent = true;
            isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (vId) => verificationId = vId,
      );
    } catch (e) {
      _showError('Phone verification not available. Please use email login.');
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().isEmpty || verificationId == null) {
      _showError('Please enter the OTP');
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: _otpController.text.trim(),
      );
      await _auth.signInWithPhoneCredential(credential);
      if (mounted) Navigator.pushReplacementNamed(context, navBar);
    } catch (e) {
      _showError('Invalid OTP. Please try again.');
    }
  }

  void _resetToPhone() {
    setState(() {
      otpSent = false;
      errorMessage = null;
      _otpController.clear();
    });
  }

  Widget _buildErrorCard() {
    if (errorMessage == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPallete.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPallete.errorColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppPallete.errorColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage!,
              style: const TextStyle(color: AppPallete.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppPallete.transparentColor,
        elevation: 0,
        title: const Text('Phone Sign In',
            style: TextStyle(color: AppPallete.whiteColor)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppPallete.whiteColor),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              otpSent ? 'Enter Verification Code' : 'Enter Phone Number',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppPallete.whiteColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              otpSent
                  ? 'We sent a 6-digit code to ${_phoneController.text}'
                  : 'We\'ll send you a verification code',
              style: const TextStyle(fontSize: 16, color: AppPallete.greyColor),
            ),
            const SizedBox(height: 32),
            if (!otpSent) ...[
              AuthField(
                hintText: 'Phone Number (+1234567890)',
                controller: _phoneController,
              ),
              const SizedBox(height: 20),
              AuthGradientButton(
                buttonText: isLoading ? 'Sending...' : 'Send Code',
                onPressed: isLoading ? () {} : _sendOTP,
              ),
            ] else ...[
              AuthField(
                hintText: 'Enter 6-digit code',
                controller: _otpController,
              ),
              const SizedBox(height: 20),
              AuthGradientButton(
                buttonText: isLoading ? 'Verifying...' : 'Verify Code',
                onPressed: isLoading ? () {} : _verifyOTP,
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _resetToPhone,
                  child: const Text('Change Phone Number',
                      style: TextStyle(color: AppPallete.gradient1)),
                ),
              ),
            ],
            _buildErrorCard(),
            const Spacer(),
            Center(
              child: TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, loginRoute),
                child: const Text(
                  'Use Email Instead',
                  style: TextStyle(color: AppPallete.gradient2, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
