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
        return web; // TODO: Add Android-specific config
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS is not configured');
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAzuqgTQHMxgxfehBb-yKN8FO20IHoPm3M',
    appId: '1:113783654616:web:9eae793d41f2d49e356fad',
    messagingSenderId: '113783654616',
    projectId: 'car-gar-6072d',
    authDomain: 'car-gar-6072d.firebaseapp.com',
    storageBucket: 'car-gar-6072d.firebasestorage.app',
    measurementId: 'G-KRSWC2S2FB',
  );
}
