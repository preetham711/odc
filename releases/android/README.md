# Android Release

## ODC_Tracker.apk

This folder holds the signed Android release APK.

**Current build:** Premium iOS-first UI with timestamp-based tracking, dual work schedules, and all features.

### Build from Windows

```powershell
# From the project root
flutter build apk --release

# Then copy to this folder:
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" `
          "releases\android\ODC_Tracker.apk"
```

Or run the convenience script from the project root:

```powershell
.\scripts\build_android_release.ps1
```

### Install on Android

1. Transfer `ODC_Tracker.apk` to your Android phone (WhatsApp, USB, email, etc.).
2. On the phone: **Settings → Security → Install unknown apps** → allow your file manager or browser.
3. Tap the APK file to install.

> **Note for iPhone users:** APK files are Android-only. They **cannot** be installed on an iPhone.
> See `releases/ios/IOS_INSTALL_GUIDE.md` for the iOS distribution process.
