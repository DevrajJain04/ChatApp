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
    final userDoc = _firestore.collection("Users").doc(userCredential.user!.uid);
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
    final GoogleSignInAccount? googleUser = await (googleInstance ?? GoogleSignIn()).signIn();
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
    if (user == null) throw FirebaseAuthException(code: 'not-authenticated', message: 'No user');

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
}
