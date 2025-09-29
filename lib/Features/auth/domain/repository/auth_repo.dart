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
  Future<void> setUsernameForCurrentUser(String username);

  // Email verification methods
  Future<void> sendEmailVerification();
  Future<void> reloadUser();
  bool isEmailVerified();

  // Phone authentication methods
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  });
  Future<UserCredential> signInWithPhoneCredential(
      PhoneAuthCredential credential);
  Future<void> linkPhoneNumber(PhoneAuthCredential credential);

  // Profile update methods
  Future<void> updateDisplayName(String displayName);
  Future<void> updateEmail(String newEmail);
  Future<void> updatePassword(String newPassword);
  Future<Map<String, dynamic>?> getUserProfile();
  Future<void> updateUserProfile(Map<String, dynamic> profileData);
}
