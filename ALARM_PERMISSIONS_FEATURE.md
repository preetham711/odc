# ⏰ Alarm & Permissions Management System

## Overview
ODC Tracker AI now includes comprehensive **alarm sound management** and **device permissions management** to ensure you never miss check-in/check-out times and the app has all necessary access.

---

## 🔔 Alarm Sound System

### Features

#### 1. **Three Alarm Types**

**Check-In Reminder**
- Reminds you to check in at start of shift
- Customizable time (default: 9:00 AM)
- Daily recurring alarm

**Check-Out Reminder**
- Reminds you to check out at end of shift
- Customizable time (default: 6:00 PM)
- Daily recurring alarm

**Break Reminder**
- Reminds you to take lunch break
- Customizable time (default: 12:30 PM)
- Daily recurring alarm

#### 2. **Custom Alarm Sounds**

- Choose from 5 built-in alarm sounds:
  - Default Alarm
  - Gentle Wake
  - Morning Bells
  - Rise and Shine
  - Peaceful Wake

- Test alarm sounds before selecting
- Plays for 3 seconds on test
- Custom sound support (future enhancement)

#### 3. **Smart Scheduling**

- Alarms scheduled only on workdays
- Uses device timezone automatically
- Respects Do Not Disturb settings (Android 12+)
- Full-screen intent for critical alarms
- LED notification lights (if supported)

#### 4. **Alarm Management**

- View all active alarms
- Enable/disable individual alarms
- Modify alarm times on the fly
- Cancel all alarms at once
- Persistent settings (saved locally)

### How to Use

#### Setup Alarms

1. Go to **Settings** → **Alarm Settings**
2. Toggle switches to enable alarms
3. Tap time display to change alarm time
4. Select preferred alarm sound
5. Test the sound with "Test Alarm Sound" button

#### Modify Alarm Time

1. Enable the alarm toggle
2. Tap on the time display (e.g., "9:00 AM")
3. Use time picker to select new time
4. Alarm reschedules automatically

#### Test Alarm Sound

1. Scroll to "Alarm Sound" section
2. Select sound from dropdown
3. Tap "Test Alarm Sound" button
4. Sound plays for 3 seconds
5. Choose your favorite

### Technical Details

**AlarmSoundService** (`lib/services/alarm_sound_service.dart`)

Key methods:
```dart
- initialize(): Setup notification channels
- scheduleCheckInReminder(): Daily check-in alarm
- scheduleCheckOutReminder(): Daily check-out alarm
- scheduleBreakReminder(): Daily break alarm
- playAlarmSound(): Play custom alarm
- cancelAlarm(): Remove specific alarm
- getScheduledAlarms(): List all active alarms
```

**Dependencies**:
- `flutter_local_notifications`: Local notification system
- `timezone`: Time zone support for scheduling
- `audioplayers`: Play custom alarm sounds
- `shared_preferences`: Save alarm settings

**Android Configuration**:
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

**iOS Configuration**:
```xml
<!-- ios/Runner/Info.plist -->
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>remote-notification</string>
</array>
```

---

## 🔒 Permissions Management System

### Overview

Comprehensive device permissions manager to ensure all features work properly.

### Permissions Tracked

| Permission | Purpose | Required |
|-----------|---------|----------|
| **Notifications** | Send check-in/check-out reminders | ✅ Yes |
| **Camera** | Capture attendance photos | ✅ Yes |
| **Storage** | Save reports and export data | ✅ Yes |
| **Location** | Verify check-in location | ⚠️ Optional |
| **Microphone** | Record voice notes | ⚠️ Optional |
| **Phone** | Handle calls during work (Android) | ⚠️ Optional |

### Permission States

Each permission can be in one of three states:

1. **✅ Granted** (Green badge)
   - Permission is active
   - Feature fully functional
   - No action needed

2. **⚠️ Not Granted** (Orange badge)
   - Permission not yet requested
   - Tap "Grant" button to request
   - Feature limited

3. **❌ Denied** (Red badge)
   - Permission permanently denied
   - Requires manual settings change
   - Tap "Open Settings" to fix

### How to Use

#### Check Permission Status

1. Go to **Settings** → **Device Permissions**
2. View all permissions with current status
3. Green badges = Good to go
4. Orange/Red badges = Action needed

#### Grant Single Permission

1. Find permission in list
2. Tap **Grant** button next to permission
3. Accept system permission dialog
4. Status updates automatically

#### Grant All Permissions

1. Scroll to bottom of permissions screen
2. Tap **Request All Permissions** button
3. Accept each system dialog
4. App requests only essential permissions

#### Fix Denied Permission

1. Locate denied permission (red badge)
2. Tap **Grant** button
3. If still denied, tap **Open System Settings**
4. Enable permission manually in device settings
5. Return to app and refresh

### Technical Details

**PermissionService** (`lib/services/permission_service.dart`)

Key methods:
```dart
- hasNotificationPermission(): Check notification access
- requestNotificationPermission(): Request notification
- hasCameraPermission(): Check camera access
- requestCameraPermission(): Request camera
- getAllPermissionStatus(): Get all permission states
- openSettings(): Open device settings app
```

**Dependencies**:
- `permission_handler`: Unified permission API
- Platform-specific: Android, iOS, Web support

**Android Configuration**:
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
```

**iOS Configuration**:
```xml
<!-- ios/Runner/Info.plist -->
<key>NSCameraUsageDescription</key>
<string>We need camera access to capture attendance photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to save attendance images</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need location access to verify check-in location</string>
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for voice notes</string>
```

### Permission Best Practices

**For Users**:
1. Grant all essential permissions (Notifications, Camera, Storage)
2. Optional permissions enhance experience but aren't required
3. If feature doesn't work, check permissions first
4. Use "Refresh" button to update permission status

**For Developers**:
1. Request permissions only when needed (just-in-time)
2. Explain why each permission is needed
3. Provide fallback for denied permissions
4. Test on both Android and iOS
5. Handle permanently denied permissions gracefully

---

## 🎯 Integration Guide

### Initialization

Both services initialize in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize alarm service
  await AlarmSoundService().initialize();
  
  // Request essential permissions
  await PermissionService.requestNotificationPermission(context);
  
  runApp(const MyApp());
}
```

### Usage in Features

**Check-In Screen**:
```dart
// Verify camera permission before showing camera
final hasCamera = await PermissionService.hasCameraPermission();
if (!hasCamera) {
  await PermissionService.requestCameraPermission(context);
}
```

**Report Export**:
```dart
// Verify storage permission before saving
final hasStorage = await PermissionService.hasStoragePermission();
if (!hasStorage) {
  await PermissionService.requestStoragePermission(context);
}
```

---

## 🚀 Future Enhancements

### Alarm System
- [ ] Custom alarm sound upload
- [ ] Snooze functionality
- [ ] Multiple alarms per type
- [ ] Alarm history tracking
- [ ] Smart alarm (wakes in light sleep)
- [ ] Geofence-based alarms
- [ ] Team-wide alarm sync

### Permissions
- [ ] Permission usage statistics
- [ ] Permission request analytics
- [ ] Guided permission setup wizard
- [ ] Permission health score
- [ ] Auto-detect missing permissions
- [ ] Permission troubleshooting assistant

---

## 🐛 Troubleshooting

### Alarms Not Working

**Problem**: Alarms don't fire at scheduled time

**Solutions**:
1. Check notification permission is granted
2. Verify alarm is enabled in settings
3. Ensure app isn't force-closed (Android)
4. Check battery optimization settings
5. Verify correct time zone
6. Reinstall app if persistent

### Permission Denied

**Problem**: Can't grant permission, always denied

**Solutions**:
1. Open device Settings → Apps → ODC Tracker
2. Tap Permissions
3. Enable required permission
4. Return to app
5. Or use "Open System Settings" button in app

### Alarm Sound Not Playing

**Problem**: Notification shows but no sound

**Solutions**:
1. Check device is not on silent mode
2. Verify notification channel settings
3. Test alarm sound in settings
4. Increase notification volume
5. Try different alarm sound

### iOS Permissions Issues

**Problem**: Permissions not requesting on iOS

**Solutions**:
1. Check Info.plist has usage descriptions
2. Delete app and reinstall
3. Reset all settings (Settings → General → Reset)
4. Update to latest iOS version

### Android 12+ Issues

**Problem**: Alarms not exact on Android 12+

**Solutions**:
1. Grant "Alarms & Reminders" permission
2. Settings → Apps → ODC Tracker → Alarms & Reminders → Allow
3. This is required for exact alarm scheduling

---

## 📱 Platform Support

| Feature | Android | iOS | Web |
|---------|---------|-----|-----|
| Alarm Sounds | ✅ Full | ✅ Full | ⚠️ Limited |
| Notifications | ✅ Full | ✅ Full | ⚠️ Limited |
| Camera Permission | ✅ Yes | ✅ Yes | ✅ Yes |
| Storage Permission | ✅ Yes | ⚠️ Photos only | ⚠️ Downloads |
| Location Permission | ✅ Yes | ✅ Yes | ✅ Yes |
| Microphone Permission | ✅ Yes | ✅ Yes | ✅ Yes |
| Phone Permission | ✅ Yes | ❌ No | ❌ No |

---

## 🎉 Conclusion

The alarm and permissions management system ensures ODC Tracker AI has everything it needs to function properly while giving you full control over device access. Never miss a check-in again, and rest assured your data and privacy are protected.

**Questions or Issues?**
- Check Settings → Device Permissions for status
- Review this documentation
- Contact support if problems persist

Happy tracking! ⏰✨
