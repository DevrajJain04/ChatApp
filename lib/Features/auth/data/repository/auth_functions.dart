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

    _firestore.collection("Users").doc(userCredential.user!.uid).set({
      "email": email,
      "uid": userCredential.user!.uid,
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

    _firestore.collection("Users").doc(userCredential.user!.uid).set({
      "email": email,
      "uid": userCredential.user!.uid,
    });
    return userCredential;
  }

  @override
  Future<UserCredential?> signInWithGoogle(
      {GoogleSignIn? googleInstance,required String username}) async {
    final GoogleSignInAccount? googleUser = await googleInstance!.signIn();
    GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
    AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
        
    _firestore.collection("Users").doc(userCredential.user!.uid).set({
      "email": googleInstance.currentUser!.email,
      "uid": userCredential.user!.uid,
    });
    return userCredential;
  }
}
