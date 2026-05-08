# AmpUp

Share Power. Share Data. Stay Connected.

## Project Overview

AmpUp is a Flutter and Firebase mobile application that helps users find nearby people who can help with battery, charger, powerbank, or data-connectivity needs. The project combines location-aware discovery, friend requests, messaging, session tracking, QR/passcode verification, credits, notifications,music player,conversational ai and AI-assisted tools into one Android-focused app experience.

The current codebase is configured for Android with Firebase. Other platforms are not configured in `lib/firebase_options.dart`.

## Problem Statement

People often run out of battery, lose access to chargers, or need connectivity when they are away from home. In urgent moments, it is difficult to know who nearby can help, how to coordinate safely, and how to reward the helper fairly.

## Solution

AmpUp creates a peer-to-peer support layer for nearby users. A user can request battery or data help, discover nearby users using location, send requests, coordinate through notifications or chat, verify battery sessions with a QR code or passcode, and exchange credits after valid sessions.

The app also includes friend-based messaging, in-app sharing, powerbank availability, charger-spot discovery/reporting, emergency alerts, local device/battery detection, and AI assistant screens.

## Features Implemented In Code

- Email/password signup, login, logout, and password reset with Firebase Authentication.
- Username and phone-based login lookup through Firestore.
- User profile records with name, username, phone, email, avatar key, credits, permissions, device data, FCM token, online status, and location.
- Dashboard navigation to battery, data, files, media, contacts, AI, friends, messages, notifications, games, music, voice-to-document, charger, powerbank, and emergency screens.
- Theme support through Provider and app theme classes.
- Android permission handling for location, Bluetooth, storage/media, and notifications.
- Device detection using Android device info and current battery level.
- Firestore-backed sessions, notifications, transactions, files, friends, chats, AI chat history, powerbank availability, charger spots, and emergency records.

Some features are prototype-level or partial. Google Places/geocoding API keys are placeholder strings in the charger, powerbank, and emergency screens. The `FileService` class is currently empty, although file/media sharing flows are implemented directly in screens and widgets. Landmark lookup in `LocationService` currently returns a placeholder value.

## Battery, Powerbank, And Charger Features

### Battery Sharing

The battery module reads the device battery percentage using `battery_plus`, shows sharing controls, scans nearby users, and creates Firestore session requests with the `battery` feature type.

Battery sessions include a generated six-digit verification code. Credits are exchanged only when the session is completed and battery verification succeeds. Emergency battery requests use a higher credit amount in `SessionService`.

### Powerbank Sharing

The powerbank screen lets a user toggle their powerbank availability. Active powerbank availability is stored in the `powerbank_available` Firestore collection with the user ID, name, active state, location, and landmark/address text.

Nearby active powerbank users can be listed and requested through a Firestore notification of type `powerbank_request`. This flow sends a request notification but does not create a full `SessionModel` session in the current code.

### Charger Discovery

The charger screen has two discovery paths:

- Nearby place search for cafes, libraries, shopping malls, and restaurants through the Google Places Nearby Search API.
- Community-reported charger spots stored in the `charger_spots` Firestore collection.

Users can report a charging spot and receive 10 credits through a direct Firestore increment. Upvote values are displayed from Firestore, but upvote interaction is not implemented in the inspected code.

## Nearby Discovery Features

AmpUp uses `geolocator` for location access. Nearby user discovery works by:

- Requesting/checking location permission.
- Updating the current user's location in Firestore.
- Querying users within a latitude bounding range.
- Filtering by longitude and computed distance.
- Sorting nearby users by distance.

Nearby discovery appears in battery/data request flows and in the share-to-friend sheet. The reusable `NearbyUsersWidget` searches within a 1 km radius, while some share flows use a 5 km radius.

## Friend Request Features

The friends screen supports:

- Searching users by username and lowercased name.
- Sending friend requests through the `friend_requests` collection.
- Preventing duplicate pending requests.
- Preventing duplicate existing friendships.
- Accepting or declining incoming requests.
- Creating reciprocal friend documents in the `friends` collection.
- Removing friends.
- Sending Firestore notifications for friend requests and accepted requests.
- Opening direct chat with a friend.

## Messaging And Sharing Features

AmpUp includes Firestore chat threads in the `chats` collection. Each chat stores participating user IDs, last message text, and last message timestamp. Messages are stored in each chat document's `messages` subcollection.

Implemented message/share behavior includes:

- Plain text chat between friends.
- Chat list and new-message flow.
- Sharing files, media, and contact cards to friends or nearby users through `ShareToFriendSheet`.
- Uploading shared files/media to Firebase Storage before sending chat messages.
- Storing shared contact payloads directly in chat messages.
- Creating share notifications.
- Awarding credits after successful in-app share actions.
- Device share sheet usage through `share_plus` in file, media, contact, and voice-to-document screens.

## Session Verification Features

Sessions are represented by `SessionModel` documents in the `sessions` collection. Session status values used in code include `requested`, `accepted`, `rejected`, and `completed`.

The implemented session lifecycle includes:

1. A requester creates a battery or data request.
2. The receiver accepts or rejects the request from notifications/session screens.
3. Accepted sessions store `started_at` and optional landmark metadata.
4. The session screen shows status, credits, other-user details, and shared location metadata.
5. Battery sessions require QR/passcode verification before credits are exchanged.
6. Data sessions require a minimum duration before credits are exchanged.
7. Completed sessions create completion notifications for both users.

Location sharing during a session stores the current address text, latitude, longitude, and a `shared_live` flag in session metadata. The current implementation stores snapshots, not continuous map tracking.

## QR And Passcode Features

Battery sessions generate a six-digit `verify_code` in session metadata. The donor can show:

- A QR code generated with `qr_flutter`.
- A manual passcode.

The requester can:

- Scan a QR code with `mobile_scanner`.
- Enter the passcode manually.

Verification calls `SessionService.verifySession()`, marks the session as verified, and completes the session if the code matches.

## Credits System

Credits are stored on the user document and transactions are stored in the `transactions` collection.

Implemented credit behavior includes:

- New users start with 10 credits.
- Battery donor credit value: 10.
- Emergency battery credit value: 20.
- Data donor credit value: 12.
- Minimum allowed credit balance: -10.
- Game credits with a daily cap of 50.
- File, media, contact, charger-spot, and in-app share rewards in the relevant screens/widgets.
- Transaction records for session-based credit/debit and game credits through `CreditService`.

Some direct screen-level credit updates use Firestore increments or direct user updates without creating `TransactionModel` records.

## Emergency Features

The emergency screen implements an SOS mode that:

- Gets the current location.
- Writes an active emergency record to the `emergencies` collection.
- Sends Firestore notifications to all friends.
- Updates location every 30 seconds while active.
- Shows quick-call buttons for police, ambulance, and fire numbers.
- Attempts to fetch nearby hospitals, police stations, and pharmacies through Google Places.
- Lets the user deactivate emergency mode.

The Google Places key is currently a placeholder, so nearby emergency-service lookup requires configuration before it can work in production.

## AI Assistant Features

The project contains two AI-related areas:

- `AiPredictionService` performs simple local linear prediction for battery and data trends.
- `AiAssistantService` and AI chat screens call the OpenRouter chat completions API.

Implemented AI screens include:

- AI insights screen for battery and data predictions.
- AI chat screen with multiple response modes.
- AI chat history stored under each user's `ai_chats` subcollection.
- Amp assistant screen with intent detection for opening app areas, playing music, sharing contacts, and asking AI questions.
- Voice input hooks through a platform method channel named `com.dakshitha.battery_barter/speech`.

The inspected code contains a hardcoded OpenRouter API key in source. For production, this should be moved to a secure backend or protected configuration before publishing.

## Notification Features

Notifications are implemented in two ways:

- Firebase Cloud Messaging setup in `main.dart` and `NotificationService`.
- Firestore notification documents in the `notifications` collection.

Implemented notification behavior includes:

- Requesting notification permission.
- Getting and storing FCM tokens.
- Listening for foreground FCM messages.
- Creating Android local notifications with `flutter_local_notifications`.
- Firestore notification streams for the notifications screen.
- Marking notifications as read.
- Creating notifications for requests, accepted/rejected sessions, session completion, friends, shares, powerbank requests, and emergency alerts.

`NotificationService.initialize()` exists, but `main.dart` currently performs its own FCM permission/token setup and foreground listener. Navigation from notification taps is noted in comments but not fully implemented.

## Firebase Services Used

The project uses:

- Firebase Core
- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging
- Firebase Storage

Firestore collections observed in code include:

- `users`
- `sessions`
- `notifications`
- `transactions`
- `files`
- `friend_requests`
- `friends`
- `chats`
- `powerbank_available`
- `charger_spots`
- `emergencies`
- `users/{uid}/ai_chats`

## Tech Stack

- Flutter
- Dart
- Firebase
- Android
- Provider for app-level state objects
- Firestore streams for real-time UI updates
- Android platform channels for speech-related features

## Flutter Packages Used

Runtime dependencies from `pubspec.yaml`:

- `http`
- `share_plus`
- `path_provider`
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_messaging`
- `firebase_storage`
- `flutter_local_notifications`
- `device_info_plus`
- `battery_plus`
- `permission_handler`
- `geolocator`
- `file_picker`
- `mobile_scanner`
- `qr_flutter`
- `fl_chart`
- `provider`
- `shared_preferences`
- `url_launcher`
- `intl`
- `uuid`
- `just_audio`
- `flutter_tts`
- `audio_service`

Development dependencies:

- `flutter_test`
- `flutter_lints`

## Folder Structure

```text
lib/
  app.dart
  main.dart
  firebase_options.dart
  game/
    dino_game.dart
    dino_obstacle.dart
    dino_player.dart
    dino_score_overlay.dart
  models/
    app_file_model.dart
    device_model.dart
    notification_model.dart
    session_model.dart
    transaction_model.dart
    user_model.dart
  screens/
    ai_chat_history_screen.dart
    ai_chat_screen.dart
    ai_screen.dart
    amp_screen.dart
    battery_screen.dart
    battery_search_screen.dart
    chat_screen.dart
    dashboard_screen.dart
    data_screen.dart
    emergency_screen.dart
    file_screen.dart
    find_charger_screen.dart
    find_powerbank_screen.dart
    friends_screen.dart
    messages_screen.dart
    notifications_screen.dart
    passcode_entry_screen.dart
    qr_display_screen.dart
    qr_screen.dart
    session_screen.dart
    signin_screen.dart
    signup_screen.dart
    plus additional feature screens
  services/
    ai_assistant_service.dart
    ai_prediction_service.dart
    auth_service.dart
    compatibility_service.dart
    contact_action_service.dart
    credit_service.dart
    device_service.dart
    file_service.dart
    firestore_service.dart
    location_service.dart
    music_player_service.dart
    nearby_service.dart
    notification_service.dart
    permission_service.dart
    session_service.dart
    voice_service.dart
    whatsapp_service.dart
  theme/
  utils/
  widgets/
android/
  app/
    google-services.json
    build.gradle.kts
assets/
  images/
test/
```

## Installation Steps

1. Install Flutter and Android Studio.
2. Clone the project.

```bash
git clone <repository-url>
cd battery_barter
```

3. Install dependencies.

```bash
flutter pub get
```

4. Verify that an Android device or emulator is available.

```bash
flutter devices
```

5. Run the app.

```bash
flutter run
```

## Firebase Setup Steps For This Project

This repository is already wired to a Firebase project named `battery-barter` for Android.

To recreate or configure the Firebase setup:

1. Create or open a Firebase project.
2. Add an Android app with package name:

```text
com.dakshitha.battery_barter
```

3. Enable Firebase Authentication and turn on Email/Password sign-in.
4. Enable Cloud Firestore.
5. Enable Firebase Cloud Messaging.
6. Enable Firebase Storage for in-app file/media sharing.
7. Download `google-services.json`.
8. Place it at:

```text
android/app/google-services.json
```

9. Ensure `lib/firebase_options.dart` is generated for Android. The current file only supports Android and throws `UnsupportedError` for web, iOS, macOS, Windows, and Linux.
10. Confirm the Android Gradle file applies Google services:

```text
id("com.google.gms.google-services")
```

11. Add any required Firestore and Storage security rules before production use.

For charger, powerbank, and emergency place lookup, replace the placeholder Google Places API key strings in the relevant Dart files with a secure configuration approach. Avoid committing real API keys to source control.

## APK Build Instructions

Build a debug APK:

```bash
flutter build apk --debug
```

Build a release APK:

```bash
flutter build apk --release
```

Expected output paths:

```text
build/app/outputs/flutter-apk/app-debug.apk
build/app/outputs/flutter-apk/app-release.apk
```

The current Android release configuration signs release builds with the debug signing config. Configure a real release keystore before publishing outside a hackathon/demo environment.

## Usage Flow

1. Open AmpUp.
2. Sign up with name, username, phone, email, and password, or sign in with email, username, or phone.
3. Grant requested permissions for location, notifications, storage/media, and related Android capabilities.
4. Use the dashboard to open battery, data, charger, powerbank, friends, messages, sharing, AI, or emergency tools.
5. Scan nearby users for battery/data help.
6. Send a request and wait for the receiver to accept or reject it.
7. Use notifications and session screens to track request status.
8. For battery sessions, verify the handoff with QR scanning or a passcode.
9. Complete the session and exchange credits when validation rules pass.
10. Add friends, chat with them, and share files/media/contacts through in-app chat.
11. Use emergency mode to alert friends and update location while active.



## Partial Or Prototype Areas Found In Code

The following items exist in the codebase but are incomplete, placeholder-based, or implemented only at prototype level:

- Google Places/geocoding calls are present in charger, powerbank, and emergency screens, but their API keys are placeholder values.
- `LocationService.getNearestLandmark()` currently returns a placeholder string instead of calling a real places/geocoding service.
- Powerbank requests create Firestore notification documents, but they do not create full `SessionModel` sessions.
- Community charger spots display stored upvote counts, but no upvote interaction was found.
- `FileService` exists but has no implementation; file/media flows are implemented directly in screens and widgets.
- Some credit rewards are direct Firestore updates and do not create `TransactionModel` records.
- Notification tap handling is noted in comments but does not include complete navigation behavior.
- Session location sharing stores current coordinate snapshots; continuous live map tracking is not implemented.
- Android release builds currently use the debug signing configuration.
- Firebase options are configured for Android only.
- AI/OpenRouter API usage is implemented directly in the client source.

## AI Disclosure

AmpUp includes AI-assisted features. The AI prediction screen uses local linear trend calculations for battery and data estimates. The AI chat and Amp assistant screens call an external chat-completions API through OpenRouter.

AI outputs and predictions are informational only. They may be inaccurate and should not be treated as guaranteed device, battery, connectivity, medical, safety, or emergency guidance. Emergency actions should rely on official services and trusted contacts.
