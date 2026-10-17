# 🚀 ODC Tracker AI - Quick Reference Card

## ⚡ Essential Commands

### Run the App
```bash
cd odc_tracker_ai
flutter run
```

### Clean Build
```bash
flutter clean
flutter pub get
flutter run
```

### Build for Release
```bash
flutter build apk --release                    # Android APK
flutter build appbundle --release              # Play Store
flutter build ios --release                    # iOS
```

### Code Analysis
```bash
flutter analyze                                # Check for issues
flutter test                                   # Run tests
```

---

## 📁 Important File Locations

| Purpose | Location |
|---------|----------|
| **Main App** | `lib/main.dart` |
| **Dashboard** | `lib/screens/dashboard/dashboard_screen.dart` |
| **ODC Service** | `lib/services/odc_service.dart` |
| **Theme** | `lib/theme/app_theme.dart` |
| **Models** | `lib/models/` |
| **Providers** | `lib/providers/` |
| **Hive Setup** | `lib/database/hive_service.dart` |
| **Firebase Config** | `android/app/google-services.json` (add this) |

---

## 🎨 Theme Colors

```dart
Primary Blue:   Color(0xFF2563EB)
Success Green:  Color(0xFF10B981)
Warning Orange: Color(0xFFF59E0B)
Danger Red:     Color(0xFFEF4444)
```

---

## 🔧 ODC Rules

| Rule | Value |
|------|-------|
| **Shift Start** | 1:00 PM |
| **Shift End** | 10:00 PM |
| **Daily Goal** | 8 hours (480 minutes) |
| **Max Break** | 1 hour (60 minutes) |
| **Multiple Breaks** | Allowed |

---

## 🔥 Firebase Quick Setup

### 1. Create Project
```
URL: https://console.firebase.google.com/
Project Name: ODC Tracker AI
```

### 2. Add Android App
```
Package: com.odctracker.odc_tracker_ai
Download: google-services.json
Place in: android/app/google-services.json
```

### 3. Add Packages
```bash
flutter pub add firebase_core firebase_auth cloud_firestore firebase_analytics
```

### 4. Configure
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 5. Initialize
```dart
// In main.dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

## 📊 Key Providers

```dart
// Today's session (updates every second)
ref.watch(todaySessionProvider)

// Current ODC time in minutes
ref.watch(currentODCTimeProvider)

// Current break time in minutes
ref.watch(currentBreakTimeProvider)

// Completion percentage (0-100)
ref.watch(completionPercentageProvider)

// Remaining ODC minutes
ref.watch(remainingODCProvider)

// Remaining break minutes
ref.watch(remainingBreakProvider)

// Current theme mode
ref.watch(themeProvider)
```

---

## 🛠️ Common Tasks

### Change Primary Color
```dart
// In lib/theme/app_theme.dart
static const Color primaryBlue = Color(0xFF2563EB); // Change this
```

### Modify Daily Goal
```dart
// Search for: 480
// Replace with your goal in minutes
// Example: 420 for 7 hours
```

### Add New Screen
```dart
// 1. Create in lib/screens/feature/feature_screen.dart
// 2. Add to lib/core/main_layout.dart
// 3. Add navigation destination
```

### Track Custom Event
```dart
import 'package:firebase_analytics/firebase_analytics.dart';

await FirebaseAnalytics.instance.logEvent(
  name: 'custom_event',
  parameters: {'key': 'value'},
);
```

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| **Build fails** | `flutter clean && flutter pub get` |
| **Hive errors** | `flutter pub run build_runner build --delete-conflicting-outputs` |
| **Firebase errors** | Check `google-services.json` is present |
| **Theme not saving** | Verify Hive initialization in `main.dart` |
| **Slow performance** | Run in Release mode: `flutter run --release` |

---

## 📱 Package Name

```
Android: com.odctracker.odc_tracker_ai
iOS: com.odctracker.odcTrackerAi
```

---

## 🔐 Security Checklist

- [x] .gitignore configured
- [ ] google-services.json not in git
- [ ] Firebase security rules configured
- [ ] ProGuard rules (if needed)
- [ ] API keys protected

---

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| **README.md** | Project overview |
| **QUICK_START.md** | Getting started |
| **PROJECT_SUMMARY.md** | Technical details |
| **FIREBASE_SETUP.md** | Firebase guide |
| **FIREBASE_NATIVE_CONFIG.md** | Native config |
| **DEPLOYMENT_CHECKLIST.md** | Launch prep |
| **FINAL_STATUS.md** | Complete status |
| **QUICK_REFERENCE.md** | This file |

---

## ⚙️ Build Configuration

| Setting | Value |
|---------|-------|
| **Min SDK** | 21 (Android 5.0) |
| **Target SDK** | Latest |
| **Compile SDK** | Latest |
| **Kotlin** | 2.1.0 |
| **Gradle** | 8.9.1 |
| **Java** | 11 |

---

## 🎯 Feature Status

| Feature | Status |
|---------|--------|
| Dashboard | ✅ Complete |
| Reports | ✅ Complete |
| Calendar | ✅ Complete |
| AI Assistant | ✅ UI Ready |
| Settings | ✅ Complete |
| Notes | 🚧 UI Ready |
| Tasks | 🚧 UI Ready |
| Firebase | ⏳ Config Ready |
| Push Notifications | ⏳ Ready to Add |
| Export | ⏳ Ready to Add |

---

## 🚀 Quick Test

After running the app:
1. Tap **"I'M IN"** on dashboard
2. Watch circular progress update
3. Tap **"START BREAK"**
4. See timeline update
5. Check Reports tab
6. Try theme switching in Settings

---

## 📞 Quick Links

- [Firebase Console](https://console.firebase.google.com/)
- [Flutter Docs](https://flutter.dev/docs)
- [Riverpod Docs](https://riverpod.dev/)
- [Hive Docs](https://docs.hivedb.dev/)
- [FlutterFire](https://firebase.flutter.dev/)

---

## 💡 Pro Tips

1. **Use Hot Reload**: Press `r` in terminal for instant updates
2. **Debug Paint**: Press `p` to see widget boundaries
3. **Performance Overlay**: Press `P` to show FPS
4. **Widget Inspector**: Use Flutter DevTools
5. **State Inspection**: Use Riverpod DevTools

---

## ✅ Daily Workflow

```bash
# Morning
cd odc_tracker_ai
flutter run

# During Development
# (Make changes)
# Press 'r' for hot reload
# Press 'R' for hot restart

# Before Committing
flutter analyze
flutter test

# End of Day
git add .
git commit -m "feat: implemented feature X"
git push
```

---

**Keep this file handy for quick reference! 📌**

**Current Status**: ✅ Ready to Use (Local Storage)
**Firebase Status**: ⏳ 2 steps away (add config file + packages)
**Time to Deploy**: ~15 minutes
