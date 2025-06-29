// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
    apiKey: 'AIzaSyA3mIugvKMtAuLjNfq09xxp2ehnNZobMao',
    appId: '1:231691677274:web:73b5e18f8f3d2620c5b263',
    messagingSenderId: '231691677274',
    projectId: 'rive-slides',
    authDomain: 'rive-slides.firebaseapp.com',
    storageBucket: 'rive-slides.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDNCQwjBX4eG_p1NinvkxSSOjrPP4KvIX8',
    appId: '1:231691677274:android:e5c7c55e0b3eb58ac5b263',
    messagingSenderId: '231691677274',
    projectId: 'rive-slides',
    storageBucket: 'rive-slides.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDZpiSiCj_QeObwVZnVUxf--o7pI7ZAJwQ',
    appId: '1:231691677274:ios:3e9ae33a6fb8d126c5b263',
    messagingSenderId: '231691677274',
    projectId: 'rive-slides',
    storageBucket: 'rive-slides.firebasestorage.app',
    iosBundleId: 'com.example.example',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDZpiSiCj_QeObwVZnVUxf--o7pI7ZAJwQ',
    appId: '1:231691677274:ios:3e9ae33a6fb8d126c5b263',
    messagingSenderId: '231691677274',
    projectId: 'rive-slides',
    storageBucket: 'rive-slides.firebasestorage.app',
    iosBundleId: 'com.example.example',
  );

}