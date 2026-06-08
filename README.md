#  KRATOS

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase&logoColor=white)](https://firebase.google.com)
[![Riverpod](https://img.shields.io/badge/State--Management-Riverpod-blueviolet?style=for-the-badge)](https://riverpod.dev)
[![Spotify](https://img.shields.io/badge/Spotify-1ED760?style=for-the-badge&logo=spotify&logoColor=white)](https://developer.spotify.com)

**Kratos** is a premium, feature-rich fitness companion and workout tracking mobile application. Built using Flutter and powered by Firebase, Kratos provides users with a cohesive workspace to schedule workouts, monitor exercises, track physical stats, and sync real-time music playback (via Spotify) to fuel their workouts.

The app features a meticulously crafted dark theme designed to offer an immersive, modern, and high-performance feel.

---

## 🚀 Key Features

### 🔐 1. Authentication & Onboarding
*   **Multi-Method Auth**: Supports traditional Email & Password, Google Sign-in, and true Firebase SMS OTP verification.
*   **Verification Safeguards**: Integrates email verification checkpoints to ensure account validity before accessing the dashboard.
*   **Google Sign-up Protection**: Implements data-preservation layers to prevent physical metrics loss during Google Account registration.
*   **Onboarding Flow**: Stepped wizard that collects user goal preferences and baseline physical metrics (weight, height, target weight, activity levels) to initialize the profile.

### 📊 2. Premium Dashboard & Daily Planner
*   **Unified Dashboard**: High-fidelity landing interface showing daily highlights, workout streaks, quick actions, and physical stats.
*   **Daily Planner**: Custom calendar-based scheduling system. Log schedules, view daily training agendas, and track historical completed workouts.
*   **Historical Viewer**: View completed workout session details, including precise start/end timestamps and set-by-set stats.

### 🏋️ 3. Workout Tracker & Exercise Library
*   **Real-time Workout Logging**: Perform workouts with an active timer, log sets, reps, and weights, and review training metrics.
*   **Exercise Database**: Rich offline library featuring categorizations by muscle groups, custom descriptions, and local/remote instructional images and videos.

### 🎵 4. Spotify Music Integration
*   **Sync & Play**: Log in via the Spotify SDK to remote-control Spotify playback within the workout session.
*   **Mini Music Player**: Persistent overlay widget showing currently playing track metadata, playback progress, and controls (Play, Pause, Skip, Shuffle, Repeat).
*   **Public Playlist Scraper**: Fallback mechanism utilizing public scraping to import open Spotify playlists, calculating track details and duration without requiring API authorization.

---

## 🛠️ Architecture & Tech Stack

Kratos uses a **Feature-First (Domain-Driven Design inspired)** folder architecture to isolate business logic, presentation components, and data repository layers.

```
lib/
├── core/                  # Core global logic (Routing, Shared themes, Providers, Utils)
│   ├── constants/         # Global constants (App colors, keys, APIs)
│   ├── providers/         # Global Shared Preferences / Storage providers
│   ├── routing/           # GoRouter configuration & route paths
│   └── theme/             # Custom light/dark themes & controllers
├── features/              # Feature modules containing presentation, domain, and data layers
│   ├── auth/              # Registration, Email verification, Sign-In, and SMS OTP
│   ├── daily_planner/     # Routine scheduler and workout history
│   ├── dashboard/         # Main dashboard interface
│   ├── exercise_library/  # Exercise viewer & search engine
│   ├── music/             # Spotify controller, playback stream & players
│   ├── onboarding/        # Multi-page physical data wizard
│   ├── profile/           # User settings, physical metrics modification, and stats
│   ├── welcome/           # Launch & welcome screens
│   └── workout/           # Active workout logging, timers, and databases
└── shared/                # Globally reused UI widgets, loading skeletons, and models
```

### Technical Specifications
*   **State Management**: Riverpod (`flutter_riverpod`) for declarative state handling and DI.
*   **Routing**: GoRouter (`go_router`) for declarative navigation and route parsing.
*   **Storage**: `shared_preferences` (theme state, basic settings) & `flutter_secure_storage` (auth tokens, secure credentials).
*   **Backend & DB**: Firebase Core, Auth, and Cloud Firestore.

---

## 📦 Dependencies

The core libraries used in Kratos include:

| Package | Purpose |
| :--- | :--- |
| `firebase_core` & `firebase_auth` | Authentication services |
| `cloud_firestore` | Secure remote database for workouts and profiles |
| `google_sign_in` | Google Single Sign-on integration |
| `flutter_riverpod` | Flexible state management & dependency injection |
| `go_router` | App navigation and deep linking |
| `spotify_sdk` | Spotify App Remote API integration |
| `audio_service` / `audio_session` | Native background audio session configuration |
| `google_fonts` | Premium typography (Outfit, Roboto) |

---

## ⚙️ Getting Started

### Prerequisites
1.  **Flutter SDK**: Ensure you have Flutter `^3.11.5` or higher installed. Run `flutter doctor` to verify.
2.  **Firebase Project**: Create a project in the Firebase Console and configure firestore security rules.
3.  **Spotify App Registration**: Register an app in the [Spotify Developer Dashboard](https://developer.spotify.com/) to obtain a Client ID. Add `kratos://callback` as a Redirect URI.

### Installation & Setup

1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/Rohithsilent/kratos.git
    cd kratos
    ```

2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Firebase Configuration**:
    Configure Firebase for Android/iOS:
    ```bash
    flutterfire configure
    ```
    This generates `lib/firebase_options.dart`.

4.  **Google Sign-in Credentials**:
    Ensure the `serverClientId` in `lib/main.dart` matches your Web Client ID from the Google Cloud Platform credentials page:
    ```dart
    await GoogleSignIn.instance.initialize(
      serverClientId: 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com',
    );
    ```

5.  **Spotify Configuration**:
    Replace the `_clientId` and `_redirectUrl` in `lib/features/music/data/services/spotify_service.dart` with your registered client information:
    ```dart
    static const String _clientId = 'YOUR_SPOTIFY_CLIENT_ID';
    static const String _redirectUrl = 'kratos://callback';
    ```

---

## 🛠️ Run & Build Commands

### Running Locally
To launch the application in debug mode on a connected device or emulator:
```bash
flutter run
```

### Build Production APK
To compile the release-ready standalone Android application package:
```bash
flutter build apk --release
```
The resulting APK will be generated under:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 🛡️ Firestore Rules

To protect user data and ensure privacy, the database is locked using the following security policy defined in `firestore.rules`:
*   **User Profiles**: Reading and writing are only permitted to authenticated owners (`request.auth.uid == userId`).
*   **Workout Logs / Sessions**: Data is restricted to the specific creator to prevent cross-account modifications.
