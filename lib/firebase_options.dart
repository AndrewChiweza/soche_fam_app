// File: lib/firebase_options.dart

// GENERATED MANUALLY FOR FLUTLAB & FLUTTERFIRE
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return web; // fallback
      case TargetPlatform.linux:
        return web; // fallback
      default:
        return web;
    }
  }

  // ---------------- WEB ----------------
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyAV4dNyuRIWh0rvw1FL0PZVn5ESgP9ssUI",
    authDomain: "choir-app-flutter.firebaseapp.com",
    projectId: "choir-app-flutter",
    storageBucket: "choir-app-flutter.firebasestorage.app",
    messagingSenderId: "8675965925",
    appId: "1:8675965925:web:66cd7c4b341fd1a5f58d0c",
    measurementId: "G-G3T2QHGXYR",
  );

  // ---------------- ANDROID (USE WEB VALUES FOR FLUTLAB) ----------------
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyAV4dNyuRIWh0rvw1FL0PZVn5ESgP9ssUI",
    authDomain: "choir-app-flutter.firebaseapp.com",
    projectId: "choir-app-flutter",
    storageBucket: "choir-app-flutter.firebasestorage.app",
    messagingSenderId: "8675965925",
    appId: "1:8675965925:web:66cd7c4b341fd1a5f58d0c",
  );

  // ---------------- iOS (NOT USED IN FLUTLAB BUT ADDED FOR COMPLETENESS) ----------------
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyAV4dNyuRIWh0rvw1FL0PZVn5ESgP9ssUI",
    authDomain: "choir-app-flutter.firebaseapp.com",
    projectId: "choir-app-flutter",
    storageBucket: "choir-app-flutter.firebasestorage.app",
    messagingSenderId: "8675965925",
    appId: "1:8675965925:web:66cd7c4b341fd1a5f58d0c",
    iosBundleId: "com.example.choirApp",
  );

  static const FirebaseOptions macos = ios;
}
