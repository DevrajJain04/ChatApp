import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yappsters/Features/auth/data/repository/auth_functions.dart';
import 'package:yappsters/core/theme/app_pallete.dart';
import 'package:yappsters/core/constants/routes.dart';
import 'package:yappsters/widgets/auth_field.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _auth = AuthFunctions();
  final _newEmailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool isLoading = false;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.getCurrentUser();
  }

  Future<void> _updateEmail() async {
    if (_newEmailController.text.trim().isEmpty) return;

    setState(() => isLoading = true);
    try {
      await _auth.updateEmail(_newEmailController.text.trim());
      await _auth.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email updated! Please verify your new email.'),
            backgroundColor: AppPallete.gradient1,
          ),
        );
        _newEmailController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppPallete.errorColor),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields'),
            backgroundColor: AppPallete.errorColor),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: _currentPasswordController.text,
      );
      await currentUser!.reauthenticateWithCredential(credential);

      // Update password
      await _auth.updatePassword(_newPasswordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password updated!'),
              backgroundColor: AppPallete.gradient1),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppPallete.errorColor),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Card(
      color: AppPallete.borderColor.withOpacity(0.3),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppPallete.gradient1),
        title:
            Text(title, style: const TextStyle(color: AppPallete.whiteColor)),
        subtitle:
            Text(subtitle, style: const TextStyle(color: AppPallete.greyColor)),
        trailing: const Icon(Icons.chevron_right, color: AppPallete.greyColor),
        onTap: onTap,
      ),
    );
  }

  void _showEmailDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppPallete.backgroundColor,
        title: const Text('Update Email',
            style: TextStyle(color: AppPallete.whiteColor)),
        content:
            AuthField(hintText: 'New Email', controller: _newEmailController),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppPallete.greyColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateEmail();
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppPallete.gradient1),
            child: const Text('Update',
                style: TextStyle(color: AppPallete.whiteColor)),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppPallete.backgroundColor,
        title: const Text('Change Password',
            style: TextStyle(color: AppPallete.whiteColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuthField(
                hintText: 'Current Password',
                controller: _currentPasswordController,
                isObscureText: true),
            const SizedBox(height: 12),
            AuthField(
                hintText: 'New Password',
                controller: _newPasswordController,
                isObscureText: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppPallete.greyColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updatePassword();
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppPallete.gradient1),
            child: const Text('Update',
                style: TextStyle(color: AppPallete.whiteColor)),
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
        title: const Text('Account Settings',
            style: TextStyle(color: AppPallete.whiteColor)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppPallete.whiteColor),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security',
              style: TextStyle(
                  color: AppPallete.whiteColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (!_auth.isEmailVerified())
              _buildSettingCard(
                icon: Icons.verified_user,
                title: 'Verify Email',
                subtitle: 'Complete email verification',
                iconColor: AppPallete.errorColor,
                onTap: () async {
                  await _auth.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verification email sent!')),
                  );
                },
              ),
            _buildSettingCard(
              icon: Icons.email,
              title: 'Change Email',
              subtitle: currentUser?.email ?? 'No email',
              onTap: _showEmailDialog,
            ),
            _buildSettingCard(
              icon: Icons.lock,
              title: 'Change Password',
              subtitle: 'Update your password',
              onTap: _showPasswordDialog,
            ),
            if (currentUser?.phoneNumber == null)
              _buildSettingCard(
                icon: Icons.phone,
                title: 'Add Phone Number',
                subtitle: 'Link phone for security',
                onTap: () => Navigator.pushNamed(context, phoneAuthRoute),
              ),
            const SizedBox(height: 24),
            const Text(
              'Account Info',
              style: TextStyle(
                  color: AppPallete.whiteColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppPallete.borderColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${currentUser?.email ?? "N/A"}',
                      style: const TextStyle(color: AppPallete.greyColor)),
                  if (currentUser?.phoneNumber != null)
                    Text('Phone: ${currentUser!.phoneNumber}',
                        style: const TextStyle(color: AppPallete.greyColor)),
                  Text(
                      'Email Verified: ${_auth.isEmailVerified() ? "Yes" : "No"}',
                      style: TextStyle(
                          color: _auth.isEmailVerified()
                              ? AppPallete.gradient1
                              : AppPallete.errorColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _newEmailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }
}
