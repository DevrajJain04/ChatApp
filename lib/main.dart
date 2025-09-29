import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:yappsters/Features/auth/presentation/pages/signup_page.dart';
import 'package:yappsters/Features/auth/presentation/pages/navbar.dart';

import 'package:yappsters/core/constants/routes.dart';
import 'package:yappsters/Features/messaging/Presentation/pages/all_chats_screen.dart';
import 'package:yappsters/core/theme/theme.dart';
import 'package:yappsters/firebase_options.dart';

import 'Features/auth/presentation/pages/login_page.dart';
import 'Features/auth/presentation/pages/phone_auth_page.dart';
import 'Features/auth/presentation/pages/email_verification_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  //   FlutterLocalNotificationsPlugin();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // await flutterLocalNotificationsPlugin.initialize(onDidReceiveBackgroundNotificationResponse: (details) => {},);
  runApp(MaterialApp(
      title: 'Yappsters',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkThemeMode,
      home: const HomePage(),
      routes: {
        loginRoute: (context) => const LogInPage(),
        signupRoute: (context) => const SignUpPage(),
        navBar: (context) => const NavBar(),
        // chatRoute:(context) => ChatPage(),
        allChats: (context) => const AllChatScreen(),
        phoneAuthRoute: (context) => const PhoneAuthPage(),
        emailVerificationRoute: (context) => const EmailVerificationPage(),
      }));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Check if email is verified for email/password users
      if (user.providerData
              .any((provider) => provider.providerId == 'password') &&
          !user.emailVerified) {
        return const EmailVerificationPage();
      }
      return const NavBar();
    } else {
      return const LogInPage();
    }
  }
}
