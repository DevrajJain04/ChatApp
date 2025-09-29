import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/repository/auth_repo.dart';

class AuthFunctions extends AuthRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  @override
  Future<UserCredential>? signUp(
      {required String email,
      required String password,
      required String userName}) async {
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
            message: 'Username already taken');
      }
      tx.set(users.doc(userCredential.user!.uid), {
        "email": email,
        "uid": userCredential.user!.uid,
        "username": userName,
        "createdAt": FieldValue.serverTimestamp(),
        "provider": "password",
      });
      tx.set(usernames.doc(userName), {"uid": userCredential.user!.uid});
    });
    return userCredential;
  }

  @override
  void signOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Future<UserCredential>? signIn(
      {required String email, required String password}) async {
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Ensure user doc exists but do not overwrite existing fields like username.
    final userDoc =
        _firestore.collection("Users").doc(userCredential.user!.uid);
    final snap = await userDoc.get();
    if (!snap.exists) {
      await userDoc.set({
        "email": email,
        "uid": userCredential.user!.uid,
        "createdAt": FieldValue.serverTimestamp(),
        "provider": "password",
      }, SetOptions(merge: true));
    }
    return userCredential;
  }

  @override
  Future<UserCredential?> signInWithGoogle(
      {GoogleSignIn? googleInstance}) async {
    final GoogleSignInAccount? googleUser =
        await (googleInstance ?? GoogleSignIn()).signIn();
    GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
    AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    // Create user document if missing.
    final users = _firestore.collection("Users");
    final userDoc = users.doc(userCredential.user!.uid);
    final snap = await userDoc.get();
    if (!snap.exists) {
      await userDoc.set({
        "email": userCredential.user!.email,
        "uid": userCredential.user!.uid,
        "createdAt": FieldValue.serverTimestamp(),
        "provider": "google",
      }, SetOptions(merge: true));
    }
    return userCredential;
  }

  @override
  Future<void> setUsernameForCurrentUser(String username) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      throw FirebaseAuthException(
          code: 'not-authenticated', message: 'No user');

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
            message: 'Username already taken');
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
      tx.set(userDocRef, {"username": username}, SetOptions(merge: true));
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

  // Phone authentication methods
  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  @override
  Future<UserCredential> signInWithPhoneCredential(
      PhoneAuthCredential credential) async {
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    // Create user document if missing
    final userDoc =
        _firestore.collection("Users").doc(userCredential.user!.uid);
    final snap = await userDoc.get();
    if (!snap.exists) {
      await userDoc.set({
        "uid": userCredential.user!.uid,
        "phoneNumber": userCredential.user!.phoneNumber,
        "createdAt": FieldValue.serverTimestamp(),
        "provider": "phone",
      }, SetOptions(merge: true));
    }

    return userCredential;
  }

  @override
  Future<void> linkPhoneNumber(PhoneAuthCredential credential) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.linkWithCredential(credential);

      // Update user document with phone number
      await _firestore.collection("Users").doc(user.uid).set({
        "phoneNumber": user.phoneNumber,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
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
