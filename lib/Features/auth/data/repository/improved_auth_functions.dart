import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/repository/auth_repo.dart';

class ImprovedAuthFunctions extends AuthRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Configure GoogleSignIn properly for Android
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    // Add your web client ID here for Android
    // serverClientId: 'YOUR_WEB_CLIENT_ID_HERE.apps.googleusercontent.com',
  );

  @override
  User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  @override
  Future<UserCredential>? signUp({
    required String email,
    required String password,
    required String userName,
  }) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile with username; enforce unique username via transaction.
      final users = _firestore.collection("Users");
      final usernames = _firestore.collection("Usernames");

      await _firestore.runTransaction((tx) async {
        final unameDoc = await tx.get(usernames.doc(userName));
        if (unameDoc.exists) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'username-already-in-use',
            message: 'Username already taken',
          );
        }
        tx.set(users.doc(userCredential.user!.uid), {
          "email": email,
          "uid": userCredential.user!.uid,
          "username": userName,
          "displayName": userName,
          "createdAt": FieldValue.serverTimestamp(),
          "provider": "password",
          "emailVerified": false,
        });
        tx.set(usernames.doc(userName), {"uid": userCredential.user!.uid});
      });

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  @override
  void signOut() async {
    try {
      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      // Silent fail for signOut
      print('Sign out error: $e');
    }
  }

  @override
  Future<UserCredential>? signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ensure user doc exists but do not overwrite existing fields
      await _ensureUserDocument(userCredential, "password");
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserCredential?> signInWithGoogle({
    GoogleSignIn? googleInstance,
  }) async {
    try {
      // Use the configured instance
      final googleSignIn = googleInstance ?? _googleSignIn;

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        throw FirebaseAuthException(
          code: 'sign-in-canceled',
          message: 'Google sign-in was canceled',
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-google-auth-token',
          message: 'Missing Google authentication token',
        );
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Ensure user document exists
      await _ensureUserDocument(userCredential, "google");

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage =
              'An account already exists with this email but different sign-in method.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid Google credentials. Please try again.';
          break;
        case 'operation-not-allowed':
          errorMessage =
              'Google sign-in is not enabled. Please contact support.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'user-not-found':
          errorMessage = 'No account found. Please sign up first.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect credentials. Please try again.';
          break;
        case 'sign-in-canceled':
          errorMessage = 'Sign-in was canceled.';
          break;
        case 'network-request-failed':
          errorMessage =
              'Network error. Please check your connection and try again.';
          break;
        default:
          errorMessage = 'Google sign-in failed: ${e.message}';
      }
      throw FirebaseAuthException(code: e.code, message: errorMessage);
    } on Exception catch (e) {
      // Handle other exceptions
      if (e.toString().contains('PlatformException')) {
        if (e.toString().contains('sign_in_canceled')) {
          throw FirebaseAuthException(
            code: 'sign-in-canceled',
            message: 'Google sign-in was canceled',
          );
        } else if (e.toString().contains('network_error')) {
          throw FirebaseAuthException(
            code: 'network-error',
            message: 'Network error. Please check your connection.',
          );
        } else if (e.toString().contains('sign_in_failed')) {
          throw FirebaseAuthException(
            code: 'sign-in-failed',
            message: 'Google sign-in failed. Please try again.',
          );
        }
      }

      throw FirebaseAuthException(
        code: 'google-sign-in-error',
        message: 'Google sign-in error: ${e.toString()}',
      );
    }
  }

  // Helper method to ensure user document exists
  Future<void> _ensureUserDocument(
      UserCredential userCredential, String provider) async {
    final user = userCredential.user!;
    final userDoc = _firestore.collection("Users").doc(user.uid);
    final snap = await userDoc.get();

    if (!snap.exists) {
      // Create new user document
      final userData = {
        "uid": user.uid,
        "email": user.email,
        "createdAt": FieldValue.serverTimestamp(),
        "provider": provider,
        "emailVerified": user.emailVerified,
      };

      // Add display name for Google users
      if (provider == "google" && user.displayName != null) {
        userData["displayName"] = user.displayName!;
      }

      await userDoc.set(userData, SetOptions(merge: true));
    } else {
      // Update existing document with login info
      await userDoc.set({
        "lastSignIn": FieldValue.serverTimestamp(),
        "emailVerified": user.emailVerified,
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<void> setUsernameForCurrentUser(String username) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'No user signed in',
      );
    }

    final usernames = _firestore.collection('Usernames');
    final users = _firestore.collection('Users');

    await _firestore.runTransaction((tx) async {
      // Ensure requested username is available
      final unameDocRef = usernames.doc(username);
      final unameDoc = await tx.get(unameDocRef);
      if (unameDoc.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'username-already-in-use',
          message: 'Username already taken',
        );
      }

      // Remove old mapping if exists
      final userDocRef = users.doc(user.uid);
      final userSnap = await tx.get(userDocRef);
      final oldUsername = userSnap.data()?['username'];
      if (oldUsername is String && oldUsername.isNotEmpty) {
        tx.delete(usernames.doc(oldUsername));
      }

      // Set new mapping and update user doc
      tx.set(unameDocRef, {"uid": user.uid});
      tx.set(
          userDocRef,
          {
            "username": username,
            "updatedAt": FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
    });
  }

  // Email verification methods
  @override
  Future<void> sendEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  @override
  Future<void> reloadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
    }
  }

  @override
  bool isEmailVerified() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.emailVerified ?? false;
  }

  // Phone authentication methods (disabled for free tier)
  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    throw FirebaseAuthException(
      code: 'phone-auth-disabled',
      message: 'Phone authentication requires a paid Firebase plan',
    );
  }

  @override
  Future<UserCredential> signInWithPhoneCredential(
      PhoneAuthCredential credential) async {
    throw FirebaseAuthException(
      code: 'phone-auth-disabled',
      message: 'Phone authentication requires a paid Firebase plan',
    );
  }

  @override
  Future<void> linkPhoneNumber(PhoneAuthCredential credential) async {
    throw FirebaseAuthException(
      code: 'phone-auth-disabled',
      message: 'Phone authentication requires a paid Firebase plan',
    );
  }

  // Profile update methods
  @override
  Future<void> updateDisplayName(String displayName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName);

      // Update Firestore document
      await _firestore.collection("Users").doc(user.uid).set({
        "displayName": displayName,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updateEmail(newEmail);

      // Update Firestore document
      await _firestore.collection("Users").doc(user.uid).set({
        "email": newEmail,
        "emailVerified": false,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await _firestore.collection("Users").doc(user.uid).get();
      if (doc.exists) {
        return doc.data();
      }
    }
    return null;
  }

  @override
  Future<void> updateUserProfile(Map<String, dynamic> profileData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      profileData['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection("Users").doc(user.uid).set(
            profileData,
            SetOptions(merge: true),
          );
    }
  }
}
