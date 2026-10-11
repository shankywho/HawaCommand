import 'package:firebase_core/firebase_core.dart';
import 'package:hawa_app/firebase/firebase_options_env.dart';

/// Firebase for the prod flavor: the `FIREBASE_*` build defines, or null. See firebase_options_env.dart.
FirebaseOptions? prodFirebaseOptions() => firebaseOptionsFromEnv();
