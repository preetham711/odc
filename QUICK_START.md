# 🚀 Quick Start Guide

## Prerequisites

Ensure you have the following installed:
- Flutter SDK 3.0+ ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Dart 3.0+
- Android Studio / Xcode (for emulator)
- VS Code or Android Studio with Flutter plugin

## Installation Steps

### 1. Navigate to Project Directory
```bash
cd odc_tracker_ai
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Generate Hive Type Adapters
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Run the App
```bash
flutter run
```

Or select your device/emulator in your IDE and press Run.

## 🎮 How to Use

### First Time Setup

1. **Launch the App**: Open ODC Tracker AI
2. **Select Theme**: Go to Settings → Choose Light/Dark/System theme
3. **Start Tracking**: Return to Dashboard

### Daily Usage

#### Check In (Start Your Shift)
1. Open the app
2. Tap the **"I'M IN"** button on the dashboard
3. Your ODC timer starts running

#### Take a Break
1. While checked in, tap **"START BREAK"**
2. Break timer starts, ODC timer pauses
3. Your break time is tracked (max 1 hour)

#### End Break
1. Tap **"END BREAK"**
2. ODC timer resumes
3. You can take multiple breaks

#### Check Out (End Your Shift)
1. Tap **"End Shift"**
2. Your total ODC time is calculated
3. Timeline is saved

### View Reports

1. Tap **Reports** icon in bottom navigation
2. Select tab: Daily / Weekly / Monthly / Yearly
3. View statistics and charts

### Calendar View

1. Tap **Calendar** icon
2. Select any date
3. View activities for that day

### Settings

1. Tap **Settings** icon
2. Configure:
   - Theme (Light/Dark/System)
   - Shift timings
   - Notifications
   - Export data

## 📊 Understanding the Dashboard

### Circular Progress
- Shows completion percentage towards 8-hour goal
- Updates in real-time every second
- Green when goal is completed
- Blue during progress

### Quick Stats Cards
- **Remaining ODC**: Time left to complete 8 hours
- **Remaining Break**: Time left from 1-hour break allowance

### Timeline
- Visual log of all check-ins, check-outs, and breaks
- Color-coded events
- Time stamps for each activity

### Today's Overview
- **Total ODC**: Your productive work time today
- **Total Break**: Your break time today

## ⚡ Keyboard Shortcuts (Desktop)

| Shortcut | Action |
|----------|--------|
| `Ctrl/Cmd + 1` | Go to Dashboard |
| `Ctrl/Cmd + 2` | Go to Reports |
| `Ctrl/Cmd + 3` | Go to Notes |
| `Ctrl/Cmd + 4` | Go to Tasks |
| `Ctrl/Cmd + 5` | Go to Calendar |
| `Ctrl/Cmd + 6` | Go to AI |
| `Ctrl/Cmd + 7` | Go to Settings |

## 🐛 Troubleshooting

### App doesn't start
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### Hive errors
```bash
# Regenerate adapters
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Theme not saving
- Ensure Hive is properly initialized
- Check app permissions
- Reinstall the app

### Data not persisting
- Check storage permissions
- Clear app data and restart
- Verify Hive database initialization

## 📱 Platform-Specific Notes

### Android
- Minimum SDK: 21 (Android 5.0)
- Target SDK: Latest
- Permissions: Storage, Notifications

### iOS
- Minimum iOS: 12.0
- Requires Xcode 14+
- Sign with your Apple Developer account

### Web
- Run with: `flutter run -d chrome`
- Some features may be limited

### Desktop (Windows/macOS/Linux)
- Run with: `flutter run -d windows/macos/linux`
- Full feature support

## 🔔 Notification Setup

### Android
Notifications work out of the box. Users can manage permissions in Settings.

### iOS
Permissions are requested on first launch. Users must allow notifications.

## 📈 Tips for Best Experience

1. **Check in at 1:00 PM** (your shift start time)
2. **Take regular breaks** to stay productive
3. **Review your reports** weekly to track progress
4. **Use AI assistant** for insights (when integrated)
5. **Enable notifications** for reminders
6. **Backup data regularly** (when feature is added)

## 🎯 ODC Rules Reminder

- **Daily Goal**: 8 hours ODC
- **Break Limit**: 1 hour maximum
- **Shift Time**: 1:00 PM - 10:00 PM
- **Multiple Breaks**: Allowed
- **Timer Logic**: ODC runs when IN, Break runs when OUT

## 🌟 Pro Tips

1. **Automatic Calculations**: Everything is calculated automatically - just focus on checking in/out
2. **Real-time Updates**: Dashboard updates every second without manual refresh
3. **Multiple Breaks**: Feel free to take multiple short breaks instead of one long break
4. **Timeline Review**: Check your timeline to see your work patterns
5. **Weekly Reports**: Review weekly reports to identify productivity trends

## 📞 Support

If you encounter any issues:

1. Check this guide first
2. Review README.md for detailed information
3. Check PROJECT_SUMMARY.md for architecture details
4. Open an issue on GitHub
5. Contact: support@odctracker.ai

## 🎨 Customization

### Change Primary Color
Edit `lib/theme/app_theme.dart`:
```dart
static const Color primaryBlue = Color(0xFF2563EB); // Change this
```

### Modify Shift Timing
Edit shift times in Settings screen or directly in code.

### Adjust Daily Goal
Change `480` (8 hours) to your desired goal in minutes in the providers.

## 🚀 Next Steps

- Explore all screens
- Try different themes
- Check the AI assistant prompts
- Review your first day's report
- Customize settings to your preference

---

**Happy Tracking! 🎉**

For more details, see [README.md](README.md) and [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)
