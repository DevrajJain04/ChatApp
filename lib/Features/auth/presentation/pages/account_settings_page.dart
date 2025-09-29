import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yappsters/Features/auth/data/repository/auth_functions.dart';
import 'package:yappsters/core/theme/app_pallete.dart';
import 'package:yappsters/widgets/auth_field.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final AuthFunctions _auth = AuthFunctions();
  final _formKey = GlobalKey<FormState>();

  final _newEmailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool isLoading = false;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.getCurrentUser();
  }

  Future<void> _updateEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await _auth.updateEmail(_newEmailController.text.trim());
      await _auth.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Email updated! Please verify your new email address.'),
            backgroundColor: AppPallete.gradient1,
          ),
        );
        _newEmailController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update email: $e'),
            backgroundColor: AppPallete.errorColor,
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppPallete.errorColor,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Re-authenticate user first
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
            content: Text('Password updated successfully!'),
            backgroundColor: AppPallete.gradient1,
          ),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update password: $e'),
            backgroundColor: AppPallete.errorColor,
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppPallete.backgroundColor,
        title: const Text('Delete Account',
            style: TextStyle(color: AppPallete.whiteColor)),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: TextStyle(color: AppPallete.greyColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppPallete.greyColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppPallete.errorColor),
            child: const Text('Delete',
                style: TextStyle(color: AppPallete.whiteColor)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => isLoading = true);
        await currentUser!.delete();

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
        }
      } catch (e) {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete account: $e'),
              backgroundColor: AppPallete.errorColor,
            ),
          );
        }
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: AppPallete.whiteColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppPallete.borderColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppPallete.gradient1),
        title: Text(
          title,
          style: const TextStyle(color: AppPallete.whiteColor, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppPallete.greyColor, fontSize: 14),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppPallete.greyColor),
        onTap: onTap,
      ),
    );
  }

  void _showEmailUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppPallete.backgroundColor,
        title: const Text('Update Email',
            style: TextStyle(color: AppPallete.whiteColor)),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AuthField(
                hintText: 'New Email Address',
                controller: _newEmailController,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppPallete.greyColor)),
          ),
          ElevatedButton(
            onPressed: isLoading
                ? null
                : () {
                    Navigator.pop(context);
                    _updateEmail();
                  },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppPallete.gradient1),
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppPallete.whiteColor),
                  )
                : const Text('Update',
                    style: TextStyle(color: AppPallete.whiteColor)),
          ),
        ],
      ),
    );
  }

  void _showPasswordUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppPallete.backgroundColor,
        title: const Text('Change Password',
            style: TextStyle(color: AppPallete.whiteColor)),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AuthField(
                hintText: 'Current Password',
                controller: _currentPasswordController,
                isObscureText: true,
              ),
              const SizedBox(height: 12),
              AuthField(
                hintText: 'New Password',
                controller: _newPasswordController,
                isObscureText: true,
              ),
              const SizedBox(height: 12),
              AuthField(
                hintText: 'Confirm New Password',
                controller: _confirmPasswordController,
                isObscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppPallete.greyColor)),
          ),
          ElevatedButton(
            onPressed: isLoading
                ? null
                : () {
                    Navigator.pop(context);
                    _updatePassword();
                  },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppPallete.gradient1),
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppPallete.whiteColor),
                  )
                : const Text('Update',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Account Security'),

            if (!_auth.isEmailVerified())
              _buildSettingsTile(
                icon: Icons.verified_user,
                title: 'Verify Email',
                subtitle: 'Complete email verification to secure your account',
                iconColor: AppPallete.errorColor,
                onTap: () async {
                  await _auth.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verification email sent!'),
                      backgroundColor: AppPallete.gradient1,
                    ),
                  );
                },
              ),

            _buildSettingsTile(
              icon: Icons.email,
              title: 'Change Email',
              subtitle: 'Update your email address',
              onTap: _showEmailUpdateDialog,
            ),

            _buildSettingsTile(
              icon: Icons.lock,
              title: 'Change Password',
              subtitle: 'Update your account password',
              onTap: _showPasswordUpdateDialog,
            ),

            if (currentUser?.phoneNumber == null)
              _buildSettingsTile(
                icon: Icons.phone,
                title: 'Add Phone Number',
                subtitle: 'Link a phone number for additional security',
                onTap: () => Navigator.pushNamed(context, '/phone-auth'),
              ),

            _buildSectionHeader('Account Management'),

            _buildSettingsTile(
              icon: Icons.download,
              title: 'Download Data',
              subtitle: 'Export your account data',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data export feature coming soon!'),
                    backgroundColor: AppPallete.gradient1,
                  ),
                );
              },
            ),

            _buildSettingsTile(
              icon: Icons.delete_forever,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account and all data',
              iconColor: AppPallete.errorColor,
              onTap: _deleteAccount,
            ),

            const SizedBox(height: 40),

            // Information card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppPallete.borderColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppPallete.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.info_outline, color: AppPallete.gradient1),
                      SizedBox(width: 8),
                      Text(
                        'Account Information',
                        style: TextStyle(
                          color: AppPallete.whiteColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Email: ${currentUser?.email ?? "N/A"}',
                    style: const TextStyle(color: AppPallete.greyColor),
                  ),
                  if (currentUser?.phoneNumber != null)
                    Text(
                      'Phone: ${currentUser!.phoneNumber}',
                      style: const TextStyle(color: AppPallete.greyColor),
                    ),
                  Text(
                    'Email Verified: ${_auth.isEmailVerified() ? "Yes" : "No"}',
                    style: TextStyle(
                      color: _auth.isEmailVerified()
                          ? AppPallete.gradient1
                          : AppPallete.errorColor,
                    ),
                  ),
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
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
