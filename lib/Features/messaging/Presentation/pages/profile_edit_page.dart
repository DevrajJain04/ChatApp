import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yappsters/Features/auth/data/repository/auth_functions.dart';
import 'package:yappsters/core/theme/app_pallete.dart';
import 'package:yappsters/widgets/auth_field.dart';
import 'package:yappsters/widgets/auth_gradient_button.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _auth = AuthFunctions();
  final _formKey = GlobalKey<FormState>();

  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();

  bool isLoading = false;
  User? currentUser;
  Map<String, dynamic>? userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);

    currentUser = _auth.getCurrentUser();
    if (currentUser != null) {
      userProfile = await _auth.getUserProfile();

      // Initialize controllers
      _displayNameController.text =
          currentUser!.displayName ?? userProfile?['displayName'] ?? '';
      _usernameController.text = userProfile?['username'] ?? '';
      _bioController.text = userProfile?['bio'] ?? '';
    }

    setState(() => isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // Update display name if changed
      if (_displayNameController.text != (currentUser?.displayName ?? '')) {
        await _auth.updateDisplayName(_displayNameController.text);
      }

      // Update username if changed
      if (_usernameController.text != (userProfile?['username'] ?? '')) {
        await _auth.setUsernameForCurrentUser(_usernameController.text);
      }

      // Update profile data in Firestore
      await _auth.updateUserProfile({
        'displayName': _displayNameController.text,
        'bio': _bioController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppPallete.gradient1,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppPallete.errorColor,
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppPallete.transparentColor,
        elevation: 0,
        title: const Text('Edit Profile',
            style: TextStyle(color: AppPallete.whiteColor)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppPallete.whiteColor),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppPallete.gradient1))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture Section
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor:
                                AppPallete.gradient1.withOpacity(0.2),
                            child: Text(
                              (_usernameController.text.isNotEmpty
                                  ? _usernameController.text
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : currentUser?.email
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      'U'),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppPallete.gradient1,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppPallete.gradient2,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt,
                                  size: 16, color: AppPallete.whiteColor),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        color: AppPallete.whiteColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

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
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Bio (optional)',
                        hintStyle: const TextStyle(color: AppPallete.greyColor),
                        filled: true,
                        fillColor: AppPallete.borderColor.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppPallete.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppPallete.gradient1),
                        ),
                      ),
                      style: const TextStyle(color: AppPallete.whiteColor),
                    ),

                    const SizedBox(height: 32),

                    AuthGradientButton(
                      buttonText: isLoading ? 'Saving...' : 'Save Changes',
                      onPressed: isLoading ? () {} : _saveProfile,
                    ),

                    const SizedBox(height: 16),

                    // Info card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppPallete.gradient1.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppPallete.gradient1.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline,
                              color: AppPallete.gradient1, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your username must be unique and can be used by others to find you.',
                              style: TextStyle(
                                  color: AppPallete.gradient1, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
