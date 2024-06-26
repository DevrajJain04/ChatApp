// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAj-jnDUz084mkGw_G6jXAX6zABNjzF9HI',
    appId: '1:477761623924:web:d30ca5a6a7095c964bbe21',
    messagingSenderId: '477761623924',
    projectId: 'yappsters-4fe4a',
    authDomain: 'yappsters-4fe4a.firebaseapp.com',
    storageBucket: 'yappsters-4fe4a.appspot.com',
    measurementId: 'G-L74W9Z121V',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAAayyKtUMZk1aMR22Mb9wy4l9natpgHG4',
    appId: '1:477761623924:android:1deaed097e82207c4bbe21',
    messagingSenderId: '477761623924',
    projectId: 'yappsters-4fe4a',
    storageBucket: 'yappsters-4fe4a.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAK_ln6HQOGwqwra1ZDKm0d1_NGQSGZysE',
    appId: '1:477761623924:ios:0110b72578dde6974bbe21',
    messagingSenderId: '477761623924',
    projectId: 'yappsters-4fe4a',
    storageBucket: 'yappsters-4fe4a.appspot.com',
    iosBundleId: 'com.example.yappsters',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAK_ln6HQOGwqwra1ZDKm0d1_NGQSGZysE',
    appId: '1:477761623924:ios:56eebb10453826e44bbe21',
    messagingSenderId: '477761623924',
    projectId: 'yappsters-4fe4a',
    storageBucket: 'yappsters-4fe4a.appspot.com',
    iosBundleId: 'com.example.yappsters.RunnerTests',
  );
}
