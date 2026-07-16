# 👶 Sara: Baby Tracker & Sounds

**Track sleep, feeding, diapers, milestones, and baby food recipes in one open-source Flutter app.**

Sara is a cross-platform mobile application developed in Flutter to assist parents and caregivers
with tracking essential baby care activities. The app supports real-time logging, shared access for
multiple caregivers, and enriched baby care insights through charts, reminders, and local/offline
support.

## 📲 Try It Now

Track every precious moment of your baby's growth — sleep, feeding, milestones, and more.

- 🟣 **[Download on the App Store](https://apps.apple.com/us/app/sara-baby-tracker-sounds/id6746516938)**
- 🟢 **[Get it on Google Play](https://play.google.com/store/apps/details?id=com.suleymansurucu.sarababy)**


---

## 🧱 High Level Architecture
The following diagram provides a high-level overview of the system architecture for the Sara: Baby Tracker & Sounds app.
It illustrates how the mobile app interacts with Firebase services, local storage, and third-party integrations.
![High Level Architecture](design/HIGH-LEVEL-ARCHITECTURE.png)

---

## 🔄 Activity Log Flow

This sequence diagram illustrates how activities are created, stored locally, and synced with Firestore.

![Activity Log Flow](design/activity_log_flow_sequence_diagram.png)

---

## 👨‍👩‍👧 Caregiver Invite & Registration Flow

This flowchart illustrates how a user can invite a caregiver and how the caregiver joins using the same baby profile.

![Caregiver Flowchart](design/caregiver_invite_flowchart.png)

---

## 🧩 Features Overview

### Feeding Tracker

- Breastfeeding (left/right)
- Bottle feeding (ml/oz)
- Pumping sessions

### Sleep Tracker

- Start/stop timers
- Sleep sound playback (white noise, lullabies etc.)
- Sleep duration analytics

### Diaper Log

- Wet / Dirty / Mixed diaper entries

### Growth & Milestones

- Monthly milestone checklist (localized)
- Weight, height tracking
- Teething & vaccination log

### Baby Recipes

- Age-filtered recipe suggestions
- Ingredients, instructions, nutrition info

### Activity History

- Timeline view (grouped by date)
- Search & filter past activities
- Edit or delete past entries

### Shared Family Access

- Multiple caregiver support
- Baby switcher for multi-baby households

---

## 🏗️ Technical Architecture

### Flutter + BLoC

- UI written using Flutter 3.x
- State management using **flutter_bloc**
- Navigation via custom `AppRouter`

### Firebase Integration

- **Firebase Auth**: User registration/login (email & password)
- **Cloud Firestore**: All activity, baby, and caregiver data
- **Firebase Storage**: For storing baby avatars locally and remotely

### Local Persistence

- **Sqflite**: Caching & offline access for activity logs
- **Shared Preferences**: Local config/settings

### Multimedia Support

- Custom background sound player with loop & fade
- Local image picker for baby avatars

---

## 🗂 Project Structure

```text
lib/
├── app/               # themes, routing
├── blocs/             # BLoC logic for each module
├── core/              # Constants, helper classes, routing, localization
├── data/
│   ├── models/        # Data models
│   ├── repositories/  # Firebase/local logic abstraction
│   └── services/      # Firebase, SQLite services
├── l10n/              # Easy localization files
├── views/
│   ├── screens/       # Pages & screens
│   ├── widgets/       # Reusable UI components
│   └── bottom_sheets/ # Bottom sheet activity forms
├── main.dart          # Entry point
├── widgets/           # Common widgets
└── firebase_options.dart # Firebase config
```
---

## 🧪 Testing

- **Unit Tests** for bloc logic and model classes
- **Widget Tests** for form behavior and UI rendering
- **Integration Tests** planned for full activity lifecycle

---

## 🔧 Setup Instructions

### Install dependencies
```bash
flutter pub get
```

### Configure Firebase

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or open an existing one.
3. Enable the following services:
    - **Authentication** (Email/Password)
    - **Cloud Firestore**
4. Register your app:
    - For **Android**, download `google-services.json`
    - For **iOS**, download `GoogleService-Info.plist`
5. Add them to:
    - `android/app/` directory (Android)
    - `ios/Runner/` directory (iOS)
6. Set up Firebase CLI (if not already):
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Or manually configure `firebase_options.dart` based on Firebase config files.

### Run the project
```bash
flutter run
```

## 📲 Deployment

### Install on a physical iPhone

Use the interactive deploy script — it builds the release bundle, lists connected devices, and installs onto the one you pick:

```bash
./scripts/deploy_ios.sh              # build release + pick device + install
./scripts/deploy_ios.sh --no-build   # reinstall the existing build output
```

Requirements: Xcode with a signing team configured, and the iPhone connected via USB and unlocked (Developer Mode enabled on iOS 16+).

---

## 🤝 Contribution Guide

1. Fork the repository
2. Create a feature branch:
   ```bash
   git checkout -b feature/my-feature
   ```
3. Make your changes and commit:
   ```bash
   git commit -m "✨ Add: new feature"
   ```
4. Push to your fork:
   ```bash
   git push origin feature/my-feature
   ```
5. Open a Pull Request

---

## ⚖️ License

This project is licensed under the **GNU GPL v3.0** license.  
See the `LICENSE` file for full license text.

---

## 📚 Resources

- [Flutter Official Docs](https://flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter BLoC](https://pub.dev/packages/flutter_bloc)
- [GoRouter Package](https://pub.dev/packages/go_router)
- [Sqflite Local DB](https://pub.dev/packages/sqflite)
- [Syncfusion Charts](https://pub.dev/packages/syncfusion_flutter_charts)




# CI/CD Test
# CI/CD Test - Thu Oct  9 22:52:17 EDT 2025
