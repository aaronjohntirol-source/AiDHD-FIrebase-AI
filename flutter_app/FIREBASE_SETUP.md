# Firebase Setup

The app uses Firebase Authentication and Cloud Firestore for accounts, profiles, and history. `SharedPreferences` is retained only for device-specific accessibility settings. If Firebase is unavailable, the app stays signed out; it never falls back to local accounts.

## 1. Create and configure a Firebase project

1. Create a project in the [Firebase Console](https://console.firebase.google.com/).
2. Enable **Authentication > Sign-in method > Email/Password**.
3. Create a **Cloud Firestore** database in production mode.
4. From `flutter_app/`, install the Firebase CLI and FlutterFire CLI:

```powershell
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

Select the Firebase project and the platforms you will run. This generates `lib/firebase_options.dart`; it contains public project identifiers, but do not put API secrets in it.

Add the Firebase packages:

```powershell
flutter pub add firebase_core firebase_auth cloud_firestore
```

Initialize Firebase before `runApp` in `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Keep the existing AppProvider initialization here.
}
```

Run `flutterfire configure` again whenever a new platform is added. Keep `firebase_options.dart` in the app; do not commit service-account JSON files.

## 2. Migrate the existing services

Keep the current service boundaries and replace their internals:

- `AuthService.register`: use `FirebaseAuth.instance.createUserWithEmailAndPassword`, then write the profile to `users/{uid}`.
- `AuthService.login`: use `signInWithEmailAndPassword`.
- `AuthService.logout`: use `FirebaseAuth.instance.signOut()`.
- `HistoryService`: use `users/{uid}/history/{entryId}` in Firestore.
- `AccessibilityService`: use `users/{uid}/settings/accessibility`, or leave it local if device-only settings are preferred.

Do not store passwords or password hashes in Firestore. Firebase Authentication owns credentials. Keep the existing `InputValidation` checks before calling Firebase and repeat important validation in security rules or trusted server code.

Suggested Firestore shape:

```text
users/{uid}
  name, age, gender, email, username, createdAt
  initialAssessmentScore, initialAssessmentCategory

users/{uid}/history/{entryId}
  type, timestamp, day, mood, note, score, category

users/{uid}/settings/accessibility
  largeText, highContrast, reducedMotion

username_index/{username}
  uid, email
```

Example Firestore rules for this user-owned data:

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }
    }
    match /username_index/{username} {
      allow read: if true;
      allow create: if request.auth != null
        && request.resource.data.uid == request.auth.uid;
      allow update, delete: if request.auth != null
        && resource.data.uid == request.auth.uid;
    }
  }
}
```

Before production, tighten field validation with `request.resource.data` checks, add App Check, and test the rules in the Firebase Emulator Suite. Do not use an allow-all rule in production.

## 3. Add the AI API later

Do not call Gemini, OpenAI, or another provider directly from Flutter with a permanent provider key. Mobile and web clients can be inspected.

Recommended flow:

```text
Flutter chat screen
  -> Firebase Callable Cloud Function (authenticated)
  -> AI provider API using a server-side secret
  -> response returned to Flutter
```

The existing AI integration point is in `lib/screens/chat_screen.dart`. When the backend is ready:

1. Add `cloud_functions` to Flutter.
2. Send the user message and the output of `AppProvider.buildAiContext()` to a callable function.
3. Store the provider key in Firebase Functions Secret Manager, not in Dart, `firebase_options.dart`, or source control.
4. Verify `request.auth != null` in the function.
5. Enforce the same ADHD-only, no-diagnosis, age-aware response rules on the server.
6. Add rate limiting, usage limits, timeout handling, and crisis-response messaging before release.

For local development or tests when the Firebase project is unavailable, use the Firebase Emulator Suite rather than local account storage. Never commit `.env` files containing provider keys.
