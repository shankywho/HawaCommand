import 'package:firebase_core/firebase_core.dart';

/// Firebase options from build defines (`--dart-define` or `env/<flavor>.json`), taken from Firebase
/// console → Project settings → Your apps → the Android app registered for this flavor's package
/// (`in.hawacommand.field.dev`, `.stg`, or `in.hawacommand.field` for prod):
/// `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`
/// (optional `FIREBASE_STORAGE_BUCKET`).
///
/// Returns null when any required value is missing, so a build without a Firebase project runs
/// without FCM and Crashlytics, exactly as before.
FirebaseOptions? firebaseOptionsFromEnv() {
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_APP_ID');
  const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  const bucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  if (apiKey.isEmpty || appId.isEmpty || senderId.isEmpty || projectId.isEmpty) return null;
  return FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: senderId,
    projectId: projectId,
    storageBucket: bucket.isEmpty ? null : bucket,
  );
}
