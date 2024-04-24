import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class AuthRepository {
  Future<UserCredential>? signUp({
    required String email,
    required String password,
    required String userName,
  });
  Future<UserCredential>? signIn({
    required String email,
    required String password,
  });
  void signOut();
  User? getCurrentUser();
  Future<UserCredential?> signInWithGoogle({GoogleSignIn? googleInstance});
}
