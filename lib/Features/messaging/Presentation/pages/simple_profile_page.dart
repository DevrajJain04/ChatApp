import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yappsters/Features/auth/data/repository/auth_functions.dart';
import 'package:yappsters/core/theme/app_pallete.dart';
import 'package:yappsters/widgets/profile_widgets.dart';
import 'profile_edit_page.dart';
import '../../../../../../Features/auth/presentation/pages/simple_account_settings.dart';

class SimpleProfilePage extends StatefulWidget {
  const SimpleProfilePage({super.key});

  @override
  State<SimpleProfilePage> createState() => _SimpleProfilePageState();
}

class _SimpleProfilePageState extends State<SimpleProfilePage> {
  final _auth = AuthFunctions();

  Map<String, dynamic>? userProfile;
  User? currentUser;
  bool isLoading = true;
  bool isVerifyingEmail = false;

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
    }
    setState(() => isLoading = false);
  }

  Future<void> _sendEmailVerification() async {
    setState(() => isVerifyingEmail = true);
    try {
      await _auth.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent!'),
            backgroundColor: AppPallete.gradient1,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('too-many-requests')) {
          errorMsg =
              'Too many requests. Please wait before sending another verification email.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppPallete.errorColor,
          ),
        );
      }
    } finally {
      setState(() => isVerifyingEmail = false);
    }
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
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
            child: Text(
              (userProfile?['username']
                      ?.toString()
                      .substring(0, 1)
                      .toUpperCase() ??
                  currentUser?.email?.substring(0, 1).toUpperCase() ??
                  'U'),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppPallete.whiteColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userProfile?['displayName'] ??
                userProfile?['username'] ??
                currentUser?.email?.split('@')[0] ??
                'User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppPallete.whiteColor,
            ),
          ),
          if (userProfile?['username'] != null)
            Text(
              '@${userProfile!['username']}',
              style:
                  const TextStyle(fontSize: 16, color: AppPallete.whiteColor),
            ),
          const SizedBox(height: 8),
          Text(
            currentUser?.email ?? '',
            style: const TextStyle(fontSize: 14, color: AppPallete.whiteColor),
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
            child: CircularProgressIndicator(color: AppPallete.gradient1)),
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
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ProfileEditPage()),
              );
              if (result == true) _loadUserProfile();
            },
            icon: const Icon(Icons.edit, color: AppPallete.whiteColor),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AccountSettingsPage()),
            ),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 20),
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
                      onPressed:
                          isVerifyingEmail ? null : _sendEmailVerification,
                      child: isVerifyingEmail
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppPallete.gradient1),
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
              value: currentUser?.phoneNumber ?? 'Not linked',
              trailing: currentUser?.phoneNumber == null
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppPallete.gradient2.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppPallete.gradient2),
                      ),
                      child: const Text(
                        'PREMIUM',
                        style: TextStyle(
                          color: AppPallete.gradient2,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const Icon(Icons.verified,
                      color: AppPallete.gradient1, size: 20),
            ),
            InfoCard(
              icon: Icons.person,
              title: 'Display Name',
              value: userProfile?['displayName'] ?? 'Not set',
            ),
            InfoCard(
              icon: Icons.alternate_email,
              title: 'Username',
              value: userProfile?['username'] ?? 'Not set',
            ),
            if (userProfile?['bio'] != null &&
                userProfile!['bio'].toString().isNotEmpty)
              InfoCard(
                icon: Icons.info_outline,
                title: 'Bio',
                value: userProfile!['bio'],
              ),
            const SectionHeader(title: 'Account Details'),
            InfoCard(
              icon: Icons.cloud,
              title: 'Sign-in Method',
              value: _getProviderName(userProfile?['provider']),
            ),
            InfoCard(
              icon: Icons.access_time,
              title: 'Member Since',
              value: _formatDate(userProfile?['createdAt']),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  String _getProviderName(String? provider) {
    switch (provider?.toLowerCase()) {
      case 'google':
        return 'Google Account';
      case 'phone':
        return 'Phone Number';
      case 'password':
      default:
        return 'Email & Password';
    }
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
}
