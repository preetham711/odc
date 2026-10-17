# ODC Tracker AI

A premium, iOS-first Flutter application for tracking mandatory ODC (On-Desk Center) working hours. Built with a modern design system, timestamp-based tracking that works even when the app is closed, dual work schedules with automatic date-based switching, and full Firebase integration.

## Features

### Core Tracking
- **I'M IN / I'M OUT** one-tap controls with haptic feedback
- **Timestamp-based calculation** — durations are always computed from stored start/end timestamps, not from running timers. Works correctly after app close, phone restart, or offline periods
- **Multiple break sessions** — take as many breaks as needed, all tracked individually
- **Auto shift-end** — the shift automatically closes when the clock reaches the schedule's end time
- **Real-time ODC ring** with live progress percentage

### Dual Work Schedules
- **Schedule A**: 1:00 PM → 10:00 PM (8h ODC, 1h break)
- **Schedule B**: 2:00 PM → 11:00 PM (8h ODC, 1h break)
- Date-aware schedule switching with `effectiveFrom` / `effectiveUntil`
- Historical reports always use the schedule that was active on that date

### Reports & Analytics
- Daily, Weekly, Monthly, and Yearly reports
- Animated bar charts with completion-based color coding
- Metrics: Total ODC, Average ODC, Perfect Days, Missed Days, Extra Time

### Calendar
- Monthly calendar with visual day status (perfect / partial / missed)
- Tap any day for detailed session breakdown

### Tasks
- Create, edit, complete, delete tasks
- Priority levels (Low, Medium, High, Urgent)
- Due dates with overdue indicators

### Notes
- Create, edit, delete, search notes
- Pin important notes, categorize, tag

### AI Assistant
- Rule-based assistant querying real Firestore data
- Architecture ready for LLM provider integration (Gemini/OpenAI)

### Notifications
- Break reminder system with configurable intervals (5/10/15/20/30/45/60 min)
- Escalation alerts at 30/45/60 minutes
- Reminders cancel immediately when user taps I'M IN
- iOS and Android compatible

### Other
- Light / Dark / System theme
- Offline support via Firestore persistence
- Firebase Authentication (mobile number + password)
- Premium iOS-first UI with spring animations and haptics

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x |
| State Management | Riverpod 2.x |
| Backend | Firebase (Auth, Firestore, Storage, Messaging) |
| Local Storage | Hive (settings cache) |
| Charts | fl_chart |
| Notifications | flutter_local_notifications |
| Design | Material 3 + iOS-first design system |

## Setup

### Prerequisites
- Flutter SDK 3.9+
- Dart 3.x
- Firebase project with Android and iOS apps configured

### Installation

```bash
git clone https://github.com/preetham711/odc.git
cd odc
flutter pub get
```

### Firebase Configuration

1. Copy the example files and fill in your real Firebase credentials:
   - `android/app/google-services.json.example` → `google-services.json`
   - `ios/Runner/GoogleService-Info.plist.example` → `GoogleService-Info.plist`
   - `lib/firebase_options.dart.example` → `firebase_options.dart`

2. Get values from Firebase Console → Project Settings

### Build

```bash
# Android APK (from Windows)
flutter build apk --release
# or
.\scripts\build_android_release.ps1

# iOS IPA (from macOS)
flutter build ipa --release
# or
./scripts/build_ios_release.sh
```

## Project Structure

```
lib/
├── core/               # Main layout + navigation
├── models/             # Data models (Firestore + Hive)
├── services/           # Firestore, Auth, ODC services
├── providers/          # Riverpod providers
├── screens/
│   ├── home/           # Premium home with I'M IN/OUT
│   ├── calendar/       # Calendar with day markers
│   ├── reports/        # Tabbed analytics + charts
│   ├── tasks/          # Task manager
│   ├── notes/          # Notes
│   ├── profile/        # iOS-style profile + settings
│   ├── settings/       # Work schedules, reminders, profile edit
│   ├── auth/           # Login, signup, forgot password
│   └── ai/             # AI assistant
├── notifications/      # Local notification engine
├── theme/              # iOS-first design system
├── database/           # Hive initialization
└── utils/              # Date/time utilities
```

## License

MIT
