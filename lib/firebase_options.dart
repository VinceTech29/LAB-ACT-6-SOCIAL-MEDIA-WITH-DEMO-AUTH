// Temporary file until 'flutterfire configure' is executed
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'dummy-api-key',
    appId: '1:1234567890:web:abcdef',
    messagingSenderId: '1234567890',
    projectId: 'demo-project',
    authDomain: 'demo-project.firebaseapp.com',
    storageBucket: 'demo-project.appspot.com',
  );
}
