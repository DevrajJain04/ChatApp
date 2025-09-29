import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yappsters/Features/auth/data/repository/auth_functions.dart';
import 'package:yappsters/core/theme/app_pallete.dart';
import 'package:yappsters/widgets/auth_field.dart';
import 'package:yappsters/widgets/auth_gradient_button.dart';
import 'package:yappsters/widgets/profile_widgets.dart';
import '../../../../../../Features/auth/presentation/pages/simple_account_settings.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthFunctions _auth = AuthFunctions();
  final _formKey = GlobalKey<FormState>();

  // Controllers for editable fields
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _newEmailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  Map<String, dynamic>? userProfile;
  User? currentUser;
  bool isLoading = true;
  bool isEditing = false;
  bool isVerifyingPhone = false;
  bool isVerifyingEmail = false;
  String? verificationId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => isLoading = true);

    currentUser = _auth.getCurrentUser();
    if (currentUser != null) {
      userProfile = await _auth.getUserProfile();

      // Initialize controllers with current data
      _displayNameController.text =
          currentUser!.displayName ?? userProfile?['displayName'] ?? '';
      _usernameController.text = userProfile?['username'] ?? '';
      _bioController.text = userProfile?['bio'] ?? '';
      _phoneController.text =
          currentUser!.phoneNumber ?? userProfile?['phoneNumber'] ?? '';
    }

    setState(() => isLoading = false);
  }

  Future<void> _sendEmailVerification() async {
    try {
      setState(() => isVerifyingEmail = true);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending verification: $e'),
            backgroundColor: AppPallete.errorColor,
          ),
        );
      }
    } finally {
      setState(() => isVerifyingEmail = false);
    }
  }

  Future<void> _verifyPhoneNumber() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a phone number'),
          backgroundColor: AppPallete.errorColor,
        ),
      );
      return;
    }

    setState(() => isVerifyingPhone = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _phoneController.text,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            if (currentUser?.phoneNumber == null) {
              await _auth.signInWithPhoneCredential(credential);
            } else {
              await _auth.linkPhoneNumber(credential);
            }
            await _loadUserProfile();
            setState(() => isVerifyingPhone = false);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Phone number verified successfully!'),
                  backgroundColor: AppPallete.gradient1,
                ),
              );
            }
          } catch (e) {
            setState(() => isVerifyingPhone = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Verification failed: $e'),
                  backgroundColor: AppPallete.errorColor,
                ),
              );
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => isVerifyingPhone = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Phone verification failed: ${e.message}'),
              backgroundColor: AppPallete.errorColor,
            ),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            this.verificationId = verificationId;
            isVerifyingPhone = false;
          });
          _showOTPDialog();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() => this.verificationId = verificationId);
        },
      );
    } catch (e) {
      setState(() => isVerifyingPhone = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppPallete.errorColor,
        ),
      );
    }
  }

  void _showOTPDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppPallete.backgroundColor,
        title: const Text('Enter OTP',
            style: TextStyle(color: AppPallete.whiteColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the 6-digit code sent to ${_phoneController.text}',
              style: const TextStyle(color: AppPallete.greyColor),
            ),
            const SizedBox(height: 16),
            AuthField(
              hintText: 'Enter OTP',
              controller: _otpController,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _otpController.clear();
            },
            child: const Text('Cancel',
                style: TextStyle(color: AppPallete.greyColor)),
          ),
          ElevatedButton(
            onPressed: _verifyOTP,
            style:
                ElevatedButton.styleFrom(backgroundColor: AppPallete.gradient1),
            child: const Text('Verify',
                style: TextStyle(color: AppPallete.whiteColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyOTP() async {
    if (verificationId == null || _otpController.text.isEmpty) return;

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: _otpController.text,
      );

      if (currentUser?.phoneNumber == null) {
        await _auth.signInWithPhoneCredential(credential);
      } else {
        await _auth.linkPhoneNumber(credential);
      }

      await _loadUserProfile();
      Navigator.pop(context);
      _otpController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number verified successfully!'),
          backgroundColor: AppPallete.gradient1,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid OTP: $e'),
          backgroundColor: AppPallete.errorColor,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => isLoading = true);

      // Update display name if changed
      if (_displayNameController.text != (currentUser?.displayName ?? '')) {
        await _auth.updateDisplayName(_displayNameController.text);
      }

      // Update username if changed
      if (_usernameController.text != (userProfile?['username'] ?? '')) {
        await _auth.setUsernameForCurrentUser(_usernameController.text);
      }

      // Update profile data
      Map<String, dynamic> profileUpdates = {
        'displayName': _displayNameController.text,
        'bio': _bioController.text,
      };

      await _auth.updateUserProfile(profileUpdates);
      await _loadUserProfile();

      setState(() => isEditing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppPallete.gradient1,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: AppPallete.errorColor,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppPallete.gradient1,
            AppPallete.gradient2,
            AppPallete.gradient3
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppPallete.whiteColor.withOpacity(0.3),
            child: Icon(
              Icons.person,
              size: 50,
              color: AppPallete.whiteColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _displayNameController.text.isEmpty
                ? (currentUser?.email?.split('@')[0] ?? 'User')
                : _displayNameController.text,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppPallete.whiteColor,
            ),
          ),
          if (_usernameController.text.isNotEmpty)
            Text(
              '@${_usernameController.text}',
              style: const TextStyle(
                fontSize: 16,
                color: AppPallete.whiteColor,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            currentUser?.email ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: AppPallete.whiteColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppPallete.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: AppPallete.gradient1),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppPallete.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppPallete.transparentColor,
        elevation: 0,
        title: const Text('Profile',
            style: TextStyle(color: AppPallete.whiteColor)),
        actions: [
          IconButton(
            onPressed: () => setState(() => isEditing = !isEditing),
            icon: Icon(
              isEditing ? Icons.close : Icons.edit,
              color: AppPallete.whiteColor,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AccountSettingsPage()),
              );
            },
            icon: const Icon(Icons.settings, color: AppPallete.whiteColor),
          ),
          IconButton(
            onPressed: () {
              _auth.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            icon: const Icon(Icons.logout, color: AppPallete.errorColor),
          ),
        ],
      ),
      body: isEditing ? _buildEditForm() : _buildProfileView(),
    );
  }

  Widget _buildProfileView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 20),

          // Account Information Section
          const SectionHeader(title: 'Account Information'),

          InfoCard(
            icon: Icons.email,
            title: 'Email',
            value: currentUser?.email ?? '',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_auth.isEmailVerified())
                  const Icon(Icons.verified,
                      color: AppPallete.gradient1, size: 20)
                else
                  TextButton(
                    onPressed: isVerifyingEmail ? null : _sendEmailVerification,
                    child: isVerifyingEmail
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppPallete.gradient1,
                            ),
                          )
                        : const Text('Verify',
                            style: TextStyle(color: AppPallete.gradient1)),
                  ),
              ],
            ),
          ),

          InfoCard(
            icon: Icons.phone,
            title: 'Phone',
            value: currentUser?.phoneNumber ?? '',
            trailing: currentUser?.phoneNumber == null
                ? TextButton(
                    onPressed: isVerifyingPhone ? null : _verifyPhoneNumber,
                    child: isVerifyingPhone
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppPallete.gradient1,
                            ),
                          )
                        : const Text('Add',
                            style: TextStyle(color: AppPallete.gradient1)),
                  )
                : const Icon(Icons.verified,
                    color: AppPallete.gradient1, size: 20),
          ),

          InfoCard(
            icon: Icons.person,
            title: 'Display Name',
            value: _displayNameController.text,
          ),

          InfoCard(
            icon: Icons.alternate_email,
            title: 'Username',
            value: _usernameController.text,
          ),

          InfoCard(
            icon: Icons.info_outline,
            title: 'Bio',
            value: _bioController.text,
          ),

          const SizedBox(height: 30),

          // Account Details Section
          const SectionHeader(title: 'Account Details'),

          InfoCard(
            icon: Icons.cloud,
            title: 'Sign-in Provider',
            value:
                userProfile?['provider']?.toString().toUpperCase() ?? 'EMAIL',
          ),

          InfoCard(
            icon: Icons.access_time,
            title: 'Member Since',
            value: userProfile?['createdAt'] != null
                ? _formatDate(userProfile!['createdAt'])
                : 'Unknown',
          ),

          if (userProfile?['updatedAt'] != null)
            InfoCard(
              icon: Icons.update,
              title: 'Last Updated',
              value: _formatDate(userProfile!['updatedAt']),
            ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Profile',
              style: TextStyle(
                color: AppPallete.whiteColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            AuthField(
              hintText: 'Display Name',
              controller: _displayNameController,
            ),
            const SizedBox(height: 16),
            AuthField(
              hintText: 'Username',
              controller: _usernameController,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                hintText: 'Bio (optional)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            if (currentUser?.phoneNumber == null) ...[
              AuthField(
                hintText: 'Phone Number (optional)',
                controller: _phoneController,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: isVerifyingPhone ? null : _verifyPhoneNumber,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPallete.gradient2,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: isVerifyingPhone
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppPallete.whiteColor,
                        ),
                      )
                    : const Text(
                        'Verify Phone Number',
                        style: TextStyle(color: AppPallete.whiteColor),
                      ),
              ),
              const SizedBox(height: 16),
            ],
            AuthGradientButton(
              buttonText: 'Save Changes',
              onPressed: _saveProfile,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    try {
      if (timestamp == null) return 'Unknown';

      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp.runtimeType.toString().contains('Timestamp')) {
        date = timestamp.toDate();
      } else {
        return 'Unknown';
      }

      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _newEmailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
