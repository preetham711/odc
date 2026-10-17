# 🔥 Firebase Setup - Required Before Running

## ⚠️ IMPORTANT: You must complete these steps before running the app

Your app is **fully configured with Firebase authentication and backend**, but you need to add your Firebase project configuration.

---

## 🚀 Quick Setup (5-10 minutes)

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Create a project"** or **"Add project"**
3. Enter project name: **`odc-tracker-ai`** (or your preferred name)
4. Disable Google Analytics (optional, you can enable later)
5. Click **"Create project"**

### Step 2: Add Android App to Firebase

1. In your Firebase project, click the **Android icon** (⚙️)
2. Register app with these details:
   - **Package name**: `com.odctracker.odc_tracker_ai` (MUST match exactly)
   - **App nickname**: `ODC Tracker AI` (optional)
   - **Debug signing certificate SHA-1**: Leave blank for now
3. Click **"Register app"**
4. **Download `google-services.json`** file
5. Move the downloaded file to:
   ```
   odc_tracker_ai/android/app/google-services.json
   ```

### Step 3: Enable Firebase Services

In Firebase Console, enable these services:

#### A. Authentication
1. Go to **Build** → **Authentication**
2. Click **"Get started"**
3. Enable **Email/Password** sign-in method
4. Click **"Save"**

#### B. Cloud Firestore
1. Go to **Build** → **Firestore Database**
2. Click **"Create database"**
3. Select **"Start in test mode"** (we'll add security rules later)
4. Choose location (nearest to your users)
5. Click **"Enable"**

#### C. Security Rules (Important!)
After creating Firestore, go to **Rules** tab and paste:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isOwner(userId);
      allow create: if isAuthenticated();
      allow update: if isOwner(userId);
      allow delete: if isOwner(userId);
      
      // User's subcollections
      match /{document=**} {
        allow read, write: if isOwner(userId);
      }
    }
  }
}
```

Click **"Publish"** to save the rules.

### Step 4: Run FlutterFire Configure

Open terminal in your project folder and run:

```bash
# Install FlutterFire CLI (one-time)
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

Follow the prompts:
- Select your Firebase project
- Choose platforms: **Android** (select with space, enter to confirm)
- It will generate `lib/firebase_options.dart` automatically

### Step 5: Run the App!

```bash
flutter run
```

---

## 📱 What Will Happen

1. **Splash Screen** appears for 2 seconds
2. App checks if user is logged in
3. If not logged in → **Login Screen**
4. If logged in → **Dashboard**

---

## 🎯 Test the App

### 1. Create Account
- Tap **"Create Account"** on login screen
- Fill in:
  - Full Name: `John Doe`
  - Mobile Number: `1234567890` (or your number)
  - Password: `password123` (minimum 8 characters)
  - Confirm Password: `password123`
- Tap **"Create Account"**
- Account will be created in Firebase

### 2. Login
- Enter mobile number and password
- Tap **"Login"**
- You'll be taken to the dashboard

### 3. Track Attendance
- Tap **"I'M IN"** to check in
- See progress circle update in real-time
- Tap **"START BREAK"** to take a break
- Tap **"END BREAK"** to return to work
- Tap **"End Shift"** when done

### 4. Check Firestore
- Go to Firebase Console → Firestore Database
- You'll see your data being stored:
  - `users/{userId}` - Your profile
  - `users/{userId}/attendance/{date}` - Today's attendance
  - Real-time sync! ✅

---

## 🐛 Troubleshooting

### "google-services.json not found"
**Solution**: Make sure the file is at `odc_tracker_ai/android/app/google-services.json`

### "Firebase project not found"
**Solution**: Run `flutterfire configure` again

### "Permission denied" in Firestore
**Solution**: Check security rules are published correctly

### App crashes on startup
**Solution**: 
```bash
flutter clean
flutter pub get
flutter run
```

### Can't create account
**Solution**: 
- Check Firebase Authentication is enabled
- Check internet connection
- Check email/password provider is enabled in Firebase Console

---

## ✅ Verification Checklist

Before running:
- [ ] Firebase project created
- [ ] Android app added to Firebase
- [ ] `google-services.json` downloaded and placed
- [ ] Authentication enabled (Email/Password)
- [ ] Firestore database created
- [ ] Security rules published
- [ ] `flutterfire configure` run successfully
- [ ] `lib/firebase_options.dart` exists

After setup complete:
- [ ] App launches successfully
- [ ] Can create account
- [ ] Can log in
- [ ] Can check in/out
- [ ] Data appears in Firestore
- [ ] Offline mode works

---

## 📚 What's Already Implemented

✅ Complete Firebase authentication
✅ User registration with validation
✅ Secure login/logout
✅ Password reset functionality
✅ Real-time attendance tracking to Firestore
✅ Check-in/check-out with timestamps
✅ Break management
✅ Automatic calculations
✅ Offline persistence
✅ Beautiful Material 3 UI
✅ Loading states and error handling
✅ Security rules ready

**Everything is production-ready! Just add your Firebase config and run! 🚀**

---

## 🔒 Important Notes

1. **Never commit `google-services.json`** to Git (already in `.gitignore`)
2. **Change security rules** from "test mode" to production rules after testing
3. **Enable App Check** for additional security in production
4. **Set up proper indexes** in Firestore as your data grows

---

**Time to complete setup: 5-10 minutes**
**Status after setup: Fully functional with real Firebase backend** ✅

Need help? Check `FIREBASE_BACKEND_IMPLEMENTATION.md` for detailed documentation.
