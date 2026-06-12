// МАҢЫЗДЫ: Бұл файлды автоматты жасату үшін терминалда мына командаларды іске қосыңыз:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=electronic-register-97138
//
// Осы команда сіздің firebase_options.dart файлын автоматты түрде жасайды.
// Бұл placeholder файлды ЖОЮ ТИІС ЕМЕССІЗ - flutterfire configure оны өзі ауыстырады.

// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return windows;
      default:
        return web;
    }
  }

  // TODO: flutterfire configure іске қосып нақты мәндерді алыңыз

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCNZaMOI8uT0VdVjh0u6j3pQhGUk7_O2sU',
    appId: '1:212240512714:web:9665ccf48d2d0ba385e633',
    messagingSenderId: '212240512714',
    projectId: 'electronic-register-97138',
    authDomain: 'electronic-register-97138.firebaseapp.com',
    storageBucket: 'electronic-register-97138.firebasestorage.app',
    measurementId: 'G-4VLBPJHNF0',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCNZaMOI8uT0VdVjh0u6j3pQhGUk7_O2sU',
    appId: '1:212240512714:web:14abf20e9199fa7485e633',
    messagingSenderId: '212240512714',
    projectId: 'electronic-register-97138',
    authDomain: 'electronic-register-97138.firebaseapp.com',
    storageBucket: 'electronic-register-97138.firebasestorage.app',
    measurementId: 'G-ZZ6HFEKQ4D',
  );
}
