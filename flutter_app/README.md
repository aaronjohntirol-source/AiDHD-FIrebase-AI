# AIDHD — Flutter App

Flutter/Dart version of the AIDHD app. Features login/register, ADHD likelihood screening, daily mood check-ins, daily assessments, history tracking, learn articles, and an AI chat placeholder ready for API integration.

---

## Project Structure

```
flutter_app/
├── lib/
│   ├── main.dart                      # Entry point
│   ├── app.dart                       # Root widget + screen router
│   ├── models/
│   │   ├── user.dart                  # User model (matches React User interface)
│   │   └── history_entry.dart         # HistoryEntry model
│   ├── services/
│   │   ├── auth_service.dart          # Login/register (SharedPreferences → Supabase)
│   │   └── history_service.dart       # Per-user history persistence
│   ├── providers/
│   │   └── app_provider.dart          # Global state (Provider) + buildAiContext()
│   ├── theme/
│   │   └── app_theme.dart             # AIDHD color tokens + Material 3 theme
│   ├── widgets/
│   │   └── bottom_nav.dart            # Shared bottom navigation bar
│   └── screens/
│       ├── login_screen.dart
│       ├── signup_screen.dart
│       ├── initial_assessment_screen.dart
│       ├── home_screen.dart
│       ├── chat_screen.dart
│       ├── profile_screen.dart
│       ├── settings_screen.dart
│       └── remaining_screens.dart     # History, Mood, Assessment, Learn, Notifications, etc.
└── pubspec.yaml
```

---

## Running Locally in VS Code

### Step 1 — Install Flutter

Download and install the Flutter SDK from https://docs.flutter.dev/get-started/install

After installing, verify everything is set up:

```bash
flutter doctor
```

Fix any issues it reports (Android Studio, Xcode, Chrome, etc.) before continuing.

### Step 2 — Install the VS Code Flutter Extension

Open VS Code → Extensions (Ctrl+Shift+X) → search **Flutter** → Install.

Restart VS Code after installing.

### Step 3 — Open the flutter_app folder

**Important:** Open the `flutter_app/` subfolder directly in VS Code, **not** the parent project folder.

```
File → Open Folder → select "flutter_app"
```

### Step 4 — Generate platform folders

Flutter needs platform-specific folders (android/, ios/, web/) that are not committed to git. Run this **once** from inside the `flutter_app/` directory:

```bash
flutter create . --project-name aidhd
```

This is safe — it will not overwrite your existing Dart files.

### Step 5 — Install dependencies

```bash
flutter pub get
```

### Step 6 — Run the app

**Option A — VS Code (recommended):**
Press **F5** or go to Run → Start Debugging. Select a target device from the picker at the bottom of VS Code.

**Option B — Terminal:**

```bash
# Run on a connected Android/iOS device or emulator
flutter run

# Run in Chrome (web)
flutter run -d chrome

# Run in a specific emulator (list available devices first)
flutter devices
flutter run -d <device-id>
```

### Common Issues

| Problem | Fix |
|---|---|
| `No devices found` | Start an Android emulator in Android Studio, or connect a physical device with USB debugging on |
| `flutter: command not found` | Add Flutter's `bin/` directory to your PATH — see https://docs.flutter.dev/get-started/install |
| `google_fonts` network error | The app downloads Inter font at runtime. Make sure the emulator/device has internet access |
| Build fails on first run | Run `flutter clean && flutter pub get` then try again |

---

## Firebase backend

The app currently uses local `SharedPreferences` storage so it runs without cloud credentials. Firebase migration instructions, Firestore structure, security rules, and the secure AI API architecture are in [FIREBASE_SETUP.md](FIREBASE_SETUP.md).

All data access is isolated in `lib/services/`, so models, providers, and screens can remain unchanged while `AuthService`, `HistoryService`, and `AccessibilityService` are migrated.

---

## Adding Real AI Chat

Open `lib/screens/chat_screen.dart`. The `Future.delayed` block is marked with an `AI INTEGRATION POINT` comment — replace it with your API call.

Pass `context.read<AppProvider>().buildAiContext()` as the system prompt. It returns:

- User profile (id, name, age, gender)
- Initial ADHD likelihood screening result
- Latest daily assessment score + category
- Full history (mood logs + assessments, most recent first)
