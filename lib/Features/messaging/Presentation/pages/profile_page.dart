import 'package:flutter/material.dart';
import 'package:yappsters/Features/auth/data/repository/auth_functions.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  final AuthFunctions _auth = AuthFunctions();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Page'),
      ),
      body: Column(
        children: [
          Text(_auth.getCurrentUser()!.email!),
        ],
      ),
    );
  }
}
