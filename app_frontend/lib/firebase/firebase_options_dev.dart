import 'package:firebase_core/firebase_core.dart';
import 'package:hawa_app/firebase/firebase_options_env.dart';

/// Firebase for the dev flavor (ARCHITECTURE §16): the `FIREBASE_*` build defines, or null (no FCM,
/// no Crashlytics; fake push via the fake backend still works). See firebase_options_env.dart.
FirebaseOptions? devFirebaseOptions() => firebaseOptionsFromEnv();
