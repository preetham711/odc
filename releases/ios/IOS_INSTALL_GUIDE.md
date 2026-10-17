# iOS Install Guide — ODC Tracker AI

> **Quick summary:**
> An iPhone app cannot be installed by simply receiving a file over WhatsApp.
> iOS requires every app to be cryptographically signed by Apple.
> The easiest path for personal/team use is **TestFlight**, described in this guide.

---

## Understanding the difference: APK vs IPA vs TestFlight

| Term | What it is | Installable by tapping? |
|------|-----------|------------------------|
| **APK** | Android Package — the install file for Android phones | ✅ Yes, on Android only |
| **IPA** | iOS App Archive — the install file for iPhone/iPad | ❌ No — must be signed and distributed through Apple's pipeline |
| **TestFlight** | Apple's official beta testing service | ✅ Yes, after TestFlight app is installed |

### Why you cannot tap-to-install an IPA from WhatsApp

Apple's security model requires every app to be signed with a certificate issued by Apple.
An IPA sent through WhatsApp is not signed for your device, so iOS will refuse to open it.
This is fundamentally different from Android, where you can enable "Install unknown apps" and tap the APK.

---

## Prerequisites

Before you start, you need:

- [ ] A Mac (Intel or Apple Silicon) — macOS 13 Ventura or later recommended
- [ ] Xcode 15 or later (free from the Mac App Store)
- [ ] An **Apple Developer account** — [developer.apple.com](https://developer.apple.com) — USD $99/year
- [ ] Flutter SDK installed on the Mac
- [ ] The ODC Tracker AI project files transferred from Windows
- [ ] Your iPhone connected to the Mac via USB (or Wi-Fi pairing)

---

## Part 1 — Move the Project from Windows to Mac

### Option A: USB / External Drive
1. Copy the entire `odc_tracker_ai` folder to a USB drive or external SSD.
2. On the Mac, paste it to `~/Developer/odc_tracker_ai` (or any folder you prefer).

### Option B: Git (Recommended)
If the project is in a Git repository:
```bash
# On Windows, push to your remote
git push origin main

# On Mac, clone
git clone <your-repo-url> ~/Developer/odc_tracker_ai
```

### Option C: Cloud sync (Google Drive, iCloud, OneDrive)
Copy the project folder to your cloud drive on Windows, wait for sync, then access it on the Mac.

> **Important:** After transferring, run `flutter pub get` on the Mac to download packages.

---

## Part 2 — Install Flutter on Mac

```bash
# Using Homebrew (recommended)
brew install --cask flutter

# Verify
flutter doctor
```

Or download the Flutter SDK manually from [flutter.dev/docs/get-started/install/macos](https://flutter.dev/docs/get-started/install/macos).

Fix any issues reported by `flutter doctor` before continuing.

---

## Part 3 — Install Xcode

1. Open the Mac App Store and search for **Xcode**.
2. Install it (it's large — ~12 GB, allow time).
3. After installation, run:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```
4. Open Xcode once and accept the license agreement.

---

## Part 4 — Configure Your Apple Developer Account

1. Go to [developer.apple.com](https://developer.apple.com) and sign in.
2. Enroll in the **Apple Developer Program** if not already enrolled (USD $99/year).
3. In Xcode: **Xcode → Settings → Accounts** → click **+** → **Apple ID** → add your account.

---

## Part 5 — Configure Bundle ID

The Bundle ID uniquely identifies your app on Apple's systems.

Currently set to: **`com.odctracker.odcTrackerAi`**

1. Open the project workspace in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
   ⚠️ Always open `.xcworkspace`, never `.xcodeproj`.

2. In the Project Navigator (left panel), select **Runner** → **Runner** target → **Signing & Capabilities** tab.

3. Set **Bundle Identifier** to: `com.odctracker.odcTrackerAi`
   (or change it to match a Bundle ID you own — it must be unique on the App Store).

---

## Part 6 — Configure Signing

Still in **Runner** target → **Signing & Capabilities**:

1. Check **Automatically manage signing**.
2. Select your **Team** from the dropdown (your Apple Developer account).
3. Xcode will create and download the necessary provisioning profile automatically.

If you see red error text, make sure:
- You are signed in with your Apple Developer account (Part 4).
- The Bundle ID is not already registered to a different team.

---

## Part 7 — Configure Firebase for iOS

The Android Firebase configuration is already working.
For iOS you need to add a separate iOS app to Firebase.

### Step 1 — Add iOS app in Firebase Console

1. Open [console.firebase.google.com](https://console.firebase.google.com).
2. Select your project: **odc-tracker**.
3. Click **Add app** → iOS.
4. Enter Bundle ID: `com.odctracker.odcTrackerAi`.
5. Give it a nickname (e.g., "ODC Tracker iOS").
6. Click **Register app**.

### Step 2 — Download GoogleService-Info.plist

1. Firebase will present the `GoogleService-Info.plist` file for download.
2. Download it.

### Step 3 — Add to Xcode (IMPORTANT: must be done in Xcode, not file explorer)

1. In Xcode, right-click on the **Runner** group in the Project Navigator.
2. Select **Add Files to "Runner"...**.
3. Navigate to the downloaded `GoogleService-Info.plist`.
4. ✅ Check **Copy items if needed**.
5. ✅ Check **Add to target: Runner**.
6. Click **Add**.

### Step 4 — Update firebase_options.dart

Open `lib/firebase_options.dart` and replace the iOS placeholder values with the real values from `GoogleService-Info.plist`:

| GoogleService-Info.plist key | firebase_options.dart field |
|-----------------------------|-----------------------------|
| `API_KEY` | `apiKey` |
| `GOOGLE_APP_ID` | `appId` |
| `GCM_SENDER_ID` | `messagingSenderId` |
| `PROJECT_ID` | `projectId` |
| `STORAGE_BUCKET` | `storageBucket` |
| `BUNDLE_ID` | `iosBundleId` |

---

## Part 8 — Set iOS Deployment Target

In Xcode → **Runner** target → **General** tab:

- **Minimum Deployments**: iOS 13.0 (or higher if you want to restrict)

Also in Xcode → **Runner** project → **Info** tab, confirm `Deployment Target` matches.

---

## Part 9 — Connect Your iPhone

1. Connect your iPhone to the Mac with a USB cable.
2. On the iPhone: tap **Trust** when prompted.
3. In Xcode, the device should appear in the device selector (top toolbar).

### Enable Developer Mode on iPhone (iOS 16+)

1. On iPhone: **Settings → Privacy & Security → Developer Mode**.
2. Toggle **Developer Mode** on.
3. The phone will restart and ask to confirm — tap **Turn On**.

---

## Part 10 — Test Build on Device

Before building a release IPA, verify the app works on your phone:

```bash
# From the project root on Mac
flutter run --release
```

Xcode should compile the app and install it directly on your connected iPhone.

---

## Part 11 — Build the Signed IPA

```bash
# From the project root on Mac
flutter build ipa --release
```

The IPA will be created at:
```
build/ios/ipa/odc_tracker_ai.ipa
```

Copy it to the releases folder:
```bash
cp build/ios/ipa/odc_tracker_ai.ipa releases/ios/ODC_Tracker.ipa
```

Or use the convenience script:
```bash
./scripts/build_ios_release.sh
```

---

## Part 12 — Upload to App Store Connect

1. Open **Xcode → Open Developer Tool → Transporter** (or install Transporter from the Mac App Store).
2. Drag the IPA file into Transporter.
3. Click **Deliver**.

Alternatively, use the command line:
```bash
xcrun altool --upload-app --type ios \
  --file "releases/ios/ODC_Tracker.ipa" \
  --username "your@apple.id" \
  --password "@keychain:AC_PASSWORD"
```

---

## Part 13 — Create a TestFlight Build

After uploading, the build will appear in App Store Connect within a few minutes (sometimes up to 30 minutes after processing).

1. Open [appstoreconnect.apple.com](https://appstoreconnect.apple.com).
2. Select your app **ODC Tracker AI**.
3. Go to **TestFlight** tab.
4. Under **Internal Testing**: click **+** next to Builds and select your new build.
5. For **External Testing** (sharing with others): create an External Group, add testers by email.

> **Note:** External TestFlight requires a brief Apple review (usually < 24 hours for the first build).

---

## Part 14 — Install TestFlight on iPhone

1. On your iPhone, open the App Store.
2. Search for **TestFlight** by Apple Inc.
3. Install it (it's free).

---

## Part 15 — Install ODC Tracker AI through TestFlight

### If you are the developer

1. Open **TestFlight** on your iPhone.
2. Your app **ODC Tracker AI** will appear automatically (because you are linked to the team).
3. Tap **Install** or **Update**.

### Sharing with team members

1. In App Store Connect → TestFlight → External Testing → your group → **Add Testers**.
2. Enter tester email addresses.
3. They receive an email invitation with a TestFlight redemption link.
4. Testers install TestFlight from the App Store, tap the invitation link, and install the app.

---

## Summary

```
Windows (Kiro)
    ↓  flutter build apk --release
ODC_Tracker.apk  ──► Transfer via WhatsApp/USB ──► Install on Android ✅

Windows (Kiro)
    ↓  Transfer project to Mac
Mac + Xcode + Apple Developer Account
    ↓  flutter build ipa --release
ODC_Tracker.ipa
    ↓  Transporter / xcrun altool
App Store Connect
    ↓  TestFlight
iPhone ──► TestFlight app ──► Install ODC Tracker AI ✅
```

---

## Troubleshooting

| Error | Fix |
|-------|-----|
| `No signing certificate found` | Add your Apple ID in Xcode Settings → Accounts |
| `Provisioning profile doesn't match bundle ID` | Check Bundle ID matches exactly in Xcode and Firebase |
| `Flutter not found` | Run `flutter doctor`; add Flutter to PATH |
| `CocoaPods not installed` | Run `sudo gem install cocoapods` then `pod install` in `ios/` |
| `Build fails with Firebase errors` | Make sure GoogleService-Info.plist is added to the Xcode target |
| `TestFlight shows "Processing"` | Wait up to 30 minutes after uploading |

---

*Last updated: October 2026 — Flutter 3.x / Xcode 15 / iOS 17*
