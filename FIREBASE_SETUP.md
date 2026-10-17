# 🔥 Firebase Setup Guide

This guide will help you integrate Firebase into the ODC Tracker AI app for cloud sync and additional features.

## ✅ Prerequisites

The app is already configured with Google Services plugin. You just need to:
1. Create a Firebase project
2. Download configuration files
3. Add Firebase dependencies

## 📋 Step-by-Step Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: `ODC Tracker AI`
4. Follow the setup wizard
5. Choose your analytics preferences

### 2. Add Android App

1. In Firebase Console, click **"Add app"** → **Android**
2. Enter package name: `com.odctracker.odc_tracker_ai`
3. App nickname: `ODC Tracker AI`
4. Debug signing certificate SHA-1 (optional for now)
5. Click **"Register app"**

### 3. Download google-services.json

1. Download the `google-services.json` file from Firebase Console
2. Copy it to: `android/app/google-services.json`
3. **Important**: Do NOT commit this file to version control

```bash
# Add to .gitignore
echo "android/app/google-services.json" >> .gitignore
```

### 4. Add Firebase Dependencies

Add Firebase packages to `pubspec.yaml`:

```yaml
dependencies:
  # Firebase Core (Required)
  firebase_core: ^3.10.0
  
  # Firebase Auth (for user authentication)
  firebase_auth: ^5.3.3
  
  # Cloud Firestore (for cloud database)
  cloud_firestore: ^5.7.1
  
  # Firebase Storage (for file uploads)
  firebase_storage: ^12.4.1
  
  # Firebase Analytics (for tracking)
  firebase_analytics: ^11.4.1
  
  # Firebase Messaging (for push notifications)
  firebase_messaging: ^15.2.2
```

Then run:
```bash
flutter pub get
```

### 5. Initialize Firebase in App

Update `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Hive database
  await HiveService.init();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const ProviderScope(child: ODCTrackerApp()));
}
```

### 6. Generate Firebase Options

Run the FlutterFire CLI to generate configuration:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Generate configuration
flutterfire configure
```

This will create `lib/firebase_options.dart` with platform-specific configurations.

### 7. iOS Setup (if targeting iOS)

1. In Firebase Console, add iOS app
2. Bundle ID: `com.odctracker.odcTrackerAi`
3. Download `GoogleService-Info.plist`
4. Add to: `ios/Runner/GoogleService-Info.plist`
5. Open `ios/Runner.xcworkspace` in Xcode
6. Add the plist file to Runner target

## 🔐 Security Rules

### Firestore Rules (Example)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // ODC sessions per user
    match /sessions/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Storage Rules (Example)

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 📊 Firebase Services to Enable

In Firebase Console, enable these services:

### 1. Authentication
- Go to **Authentication** → **Sign-in method**
- Enable **Email/Password**
- Enable **Google** (optional)

### 2. Firestore Database
- Go to **Firestore Database**
- Click **"Create database"**
- Choose **"Start in test mode"** (change to production rules later)
- Select location (nearest to your users)

### 3. Cloud Storage
- Go to **Storage**
- Click **"Get started"**
- Use default security rules (modify later)

### 4. Analytics (Optional)
- Already enabled by default
- No additional setup needed

### 5. Cloud Messaging (Optional)
- Go to **Cloud Messaging**
- Enable the API
- Configure server key for push notifications

## 🔧 Implementation Examples

### Example: Sync ODC Session to Firebase

Create `lib/services/firebase_sync_service.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/odc_session.dart';

class FirebaseSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> syncSession(ODCSession session) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .doc(session.id)
        .set({
      'date': session.date.toIso8601String(),
      'checkInTime': session.checkInTime?.toIso8601String(),
      'checkOutTime': session.checkOutTime?.toIso8601String(),
      'totalODCMinutes': session.totalODCMinutes,
      'totalBreakMinutes': session.totalBreakMinutes,
      'isActive': session.isActive,
      'breaks': session.breaks.map((b) => {
        'id': b.id,
        'startTime': b.startTime?.toIso8601String(),
        'endTime': b.endTime?.toIso8601String(),
        'durationMinutes': b.durationMinutes,
      }).toList(),
    });
  }

  Stream<List<ODCSession>> streamSessions() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Convert back to ODCSession
        // Implementation here...
        return ODCSession(
          id: doc.id,
          date: DateTime.parse(data['date']),
          // ... other fields
          breaks: [],
        );
      }).toList();
    });
  }
}
```

### Example: Authentication Service

Create `lib/services/auth_service.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Register with email and password
  Future<UserCredential> registerWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
```

## 🚀 Testing Firebase Integration

### 1. Run the app
```bash
flutter run
```

### 2. Check Firebase Console
- Go to Firestore Database
- Verify data is being written
- Check Authentication for users

### 3. Test Offline Sync
- Disconnect internet
- Make changes in app
- Reconnect
- Verify data syncs automatically

## 📱 Platform-Specific Notes

### Android
- `minSdkVersion` should be at least 21
- Google Services plugin is already configured ✅
- SHA-1 fingerprint required for Google Sign-In

### iOS
- Minimum iOS 12.0
- Add `GoogleService-Info.plist` to Runner target
- Update `Info.plist` for required permissions

### Web
- Firebase works on web with minimal changes
- Follow web-specific Firebase setup

## 🔒 Security Best Practices

1. **Never commit** `google-services.json` or `GoogleService-Info.plist`
2. **Use environment variables** for sensitive keys
3. **Implement proper security rules** in Firestore
4. **Enable App Check** for additional security
5. **Use Firebase Authentication** to secure data access
6. **Regular security audits** of Firebase rules

## 📈 Monitoring & Analytics

### Enable Performance Monitoring
```yaml
dependencies:
  firebase_performance: ^0.10.4
```

### Track Custom Events
```dart
import 'package:firebase_analytics/firebase_analytics.dart';

final analytics = FirebaseAnalytics.instance;

// Track ODC session start
await analytics.logEvent(
  name: 'odc_session_start',
  parameters: {'time': DateTime.now().toString()},
);
```

## 🐛 Troubleshooting

### "google-services.json not found"
- Ensure file is in `android/app/` directory
- File name is exactly `google-services.json`

### Build errors after adding Firebase
```bash
flutter clean
flutter pub get
flutter run
```

### iOS CocoaPods issues
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter run
```

## 📚 Resources

- [Firebase Flutter Documentation](https://firebase.google.com/docs/flutter/setup)
- [FlutterFire GitHub](https://github.com/firebase/flutterfire)
- [Firebase Console](https://console.firebase.google.com/)
- [Firebase YouTube Channel](https://www.youtube.com/firebase)

## 💡 Next Steps

After Firebase setup:
1. Implement authentication flow
2. Sync ODC sessions to cloud
3. Add real-time collaboration
4. Enable push notifications
5. Add crash reporting with Firebase Crashlytics
6. Implement remote config for feature flags

---

**Ready for Firebase Integration! 🔥**

Need help? Check the [Firebase documentation](https://firebase.google.com/docs/flutter/setup) or open an issue.
