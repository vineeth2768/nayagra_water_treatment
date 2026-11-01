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
      default:
        return web;
    }
  }

  // Official Firebase Credentials for nayagrawatertreatmentplants
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAirJ37kTnT3QAPQ0IXcUu66z86x0i3PFQ',
    appId: '1:657902920245:web:a27d79e62601276522c77c',
    messagingSenderId: '657902920245',
    projectId: 'nayagrawatertreatmentplants',
    authDomain: 'nayagrawatertreatmentplants.firebaseapp.com',
    storageBucket: 'nayagrawatertreatmentplants.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAirJ37kTnT3QAPQ0IXcUu66z86x0i3PFQ',
    appId: '1:657902920245:android:nayagrawatertreatmentplants',
    messagingSenderId: '657902920245',
    projectId: 'nayagrawatertreatmentplants',
    storageBucket: 'nayagrawatertreatmentplants.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAirJ37kTnT3QAPQ0IXcUu66z86x0i3PFQ',
    appId: '1:657902920245:ios:nayagrawatertreatmentplants',
    messagingSenderId: '657902920245',
    projectId: 'nayagrawatertreatmentplants',
    storageBucket: 'nayagrawatertreatmentplants.firebasestorage.app',
    iosBundleId: 'com.nayagra.waterTreatment',
  );
}
