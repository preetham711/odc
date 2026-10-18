# Firebase Admin User Setup Guide

## 🎯 Goal
Create an admin user with phone number `0000011111` and password `12345678` that can access the admin dashboard.

---

## 📋 Prerequisites

- Firebase project configured
- Firebase Authentication enabled
- Firestore database created
- App connected to Firebase

---

## 🚀 Option 1: Firebase Console (Recommended)

### Step 1: Create Authentication User

1. **Go to Firebase Console**
   - Navigate to https://console.firebase.google.com
   - Select your project

2. **Open Authentication**
   - Click "Authentication" in left sidebar
   - Go to "Users" tab

3. **Add User**
   - Click "Add user" button
   - **Choose one method:**

#### Method A: Email/Password (Easier)
   ```
   Email: admin@odctracker.com
   Password: 12345678
   ```
   - Click "Add user"
   - **Copy the User UID** (you'll need this)

#### Method B: Phone Number (Production)
   ```
   Phone: +910000011111  (adjust country code)
   ```
   - Note: Requires SMS verification setup
   - May need test phone numbers configured
   - **Copy the User UID** (you'll need this)

### Step 2: Create Firestore Document

1. **Go to Firestore Database**
   - Click "Firestore Database" in left sidebar
   - Click "Start collection" if empty

2. **Create Users Collection**
   - Collection ID: `users`
   - Click "Next"

3. **Add Admin Document**
   - **Document ID:** Paste the UID from Step 1
   - Add these fields:

```
Field                    Type        Value
─────────────────────────────────────────────────────────
uid                      string      [same as document ID]
fullName                 string      "System Admin"
mobileNumber             string      "0000011111"
email                    string      "admin@odctracker.com"
employeeId               string      "ADMIN001"
role                     string      "admin"          ⭐ CRITICAL!
isDisabled               boolean     false
profilePhoto             string      null (leave empty)
createdAt                timestamp   [now]
updatedAt                timestamp   [now]
lastLogin                timestamp   [now]
shiftStart               string      "13:00"
shiftEnd                 string      "22:00"
dailyGoal                number      480
breakLimit               number      60
theme                    string      "system"
notificationEnabled      boolean     true
```

4. **Click "Save"**

### Step 3: Verify Setup

1. **Check Authentication**
   - Go to Authentication → Users
   - ✅ Should see user with phone/email

2. **Check Firestore**
   - Go to Firestore → users collection
   - ✅ Should see document with matching UID
   - ✅ Verify `role` field is exactly `"admin"` (lowercase)

---

## 🚀 Option 2: Using the Setup Script

### Step 1: Run Setup Script

1. **Add to your main.dart temporarily:**

```dart
import 'scripts/setup_admin_user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Run setup script once
  await setupAdminUser();
  
  // Then comment out the above line and continue normal flow
  runApp(const ProviderScope(child: ODCTrackerApp()));
}
```

2. **Run the app:**
```bash
flutter run
```

3. **Check console output:**
```
🔧 Setting up admin user...
✅ Admin user created successfully!

📋 Login Credentials:
   Phone: 0000011111
   Email: admin@odctracker.com
   Password: 12345678
```

4. **Comment out the setup line after success**

### Step 2: Verify

Run verification:
```dart
final user = FirebaseAuth.instance.currentUser;
if (user != null) {
  await verifyAdminUser(user.uid);
}
```

---

## 🚀 Option 3: Firebase CLI (Advanced)

### Using Firebase Admin SDK

Create a Node.js script:

```javascript
// setup-admin.js
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const auth = admin.auth();
const db = admin.firestore();

async function setupAdmin() {
  try {
    // Create auth user
    let user;
    try {
      user = await auth.createUser({
        email: 'admin@odctracker.com',
        password: '12345678',
        phoneNumber: '+910000011111',
        displayName: 'System Admin',
      });
      console.log('✅ Created auth user:', user.uid);
    } catch (error) {
      // If exists, get by email
      user = await auth.getUserByEmail('admin@odctracker.com');
      console.log('✅ Found existing user:', user.uid);
    }

    // Create Firestore document
    await db.collection('users').doc(user.uid).set({
      uid: user.uid,
      fullName: 'System Admin',
      mobileNumber: '0000011111',
      email: 'admin@odctracker.com',
      employeeId: 'ADMIN001',
      role: 'admin',
      isDisabled: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLogin: admin.firestore.FieldValue.serverTimestamp(),
      shiftStart: '13:00',
      shiftEnd: '22:00',
      dailyGoal: 480,
      breakLimit: 60,
      theme: 'system',
      notificationEnabled: true,
    });

    console.log('✅ Admin user setup complete!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

setupAdmin();
```

Run:
```bash
node setup-admin.js
```

---

## 🔐 Login Flow After Setup

### Step 1: Open App
- Launch ODC Tracker AI

### Step 2: Login Screen
Enter credentials based on your setup:

**Option A - Email/Password:**
```
Email: admin@odctracker.com
Password: 12345678
```

**Option B - Phone:**
```
Phone: 0000011111
Password: 12345678
```

### Step 3: Verify Admin Access

After login, you should see:

1. ✅ **6 tabs** in bottom navigation
2. ✅ **6th tab is "Admin"** (orange color)
3. ✅ Tap Admin → See admin dashboard
4. ✅ Dashboard shows statistics
5. ✅ 4 admin tabs: Dashboard, Users, Analytics, Settings

---

## ✅ Verification Checklist

### Firebase Console Checks

- [ ] Authentication → Users → Admin user exists
- [ ] User has email: `admin@odctracker.com` OR phone: `+910000011111`
- [ ] Firestore → users → Document with matching UID exists
- [ ] Document has `role: "admin"` (exact string, lowercase)
- [ ] Document has `isDisabled: false`

### App Checks

- [ ] Can login with credentials
- [ ] See 6 tabs after login
- [ ] Admin tab is visible and orange
- [ ] Tapping Admin shows dashboard
- [ ] Dashboard loads statistics
- [ ] Can navigate Users, Analytics, Settings tabs

---

## 🐛 Troubleshooting

### Problem: Can't login

**Possible Causes:**
1. User doesn't exist in Firebase Authentication
2. Wrong credentials
3. Phone auth not configured

**Solutions:**
- Check Firebase Console → Authentication → Users
- Verify credentials match exactly
- Try email/password method instead of phone
- Enable Email/Password provider in Authentication settings

### Problem: Login works but no Admin tab

**Possible Causes:**
1. Firestore document missing
2. `role` field not set to "admin"
3. Document UID doesn't match Auth UID

**Solutions:**
- Check Firestore → users collection
- Verify document exists with same UID as Auth user
- Check `role` field is exactly: `"admin"` (lowercase, no spaces)
- Verify `isDisabled` is `false`

### Problem: Admin tab shows but dashboard is empty

**Possible Causes:**
1. No users in database
2. Firestore security rules blocking access
3. Network connection issue

**Solutions:**
- Add test users to verify dashboard
- Check Firestore security rules allow admin reads
- Check console for errors
- Try pull-to-refresh on dashboard

### Problem: "Permission denied" errors

**Possible Causes:**
1. Firestore security rules too restrictive
2. Admin role not properly detected

**Solutions:**
Update Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAdmin() {
      return request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }
    
    match /users/{userId}/attendance/{docId} {
      allow read: if request.auth.uid == userId || isAdmin();
      allow write: if request.auth.uid == userId || isAdmin();
    }
  }
}
```

---

## 🔄 Updating Existing User to Admin

If you have an existing user and want to make them admin:

### Via Firebase Console
1. Go to Firestore → users → [user-document]
2. Find `role` field
3. Change value from `"user"` to `"admin"`
4. Save
5. User must log out and back in

### Via App (Another Admin)
1. Login as existing admin
2. Go to Admin → Users
3. Find the user
4. Tap user → Grant Admin Access
5. Confirm

### Via Script
```dart
await grantAdminAccess('user-uid-here');
```

---

## 🔒 Security Best Practices

### Production Deployment

1. **Change Default Password**
   - Don't use `12345678` in production
   - Use strong, unique password
   - Consider password requirements

2. **Limit Admin Accounts**
   - Only trusted personnel
   - Regular access audits
   - Revoke when no longer needed

3. **Enable 2FA** (if available)
   - Additional security layer
   - Required for sensitive operations

4. **Monitor Admin Actions**
   - Log admin operations
   - Review regularly
   - Alert on suspicious activity

5. **Secure Firebase Rules**
   - Verify admin role server-side
   - Don't trust client-side checks
   - Test rules thoroughly

---

## 📞 Support

### Need Help?

1. **Check Firebase Console**
   - Authentication status
   - Firestore documents
   - Security rules

2. **Review App Logs**
   - Console errors
   - Network requests
   - Provider states

3. **Verify Setup**
   - Run verification script
   - Check all fields present
   - Confirm role spelling

4. **Common Issues**
   - See Troubleshooting section above
   - Review error messages
   - Check network connectivity

---

## ✅ Quick Setup Summary

**Fastest method:**

1. Firebase Console → Authentication → Add user
   - Email: `admin@odctracker.com`
   - Password: `12345678`
   - Copy UID

2. Firebase Console → Firestore → users collection
   - Document ID: [paste UID]
   - Add all fields (see template above)
   - **CRITICAL:** `role: "admin"`

3. Open app → Login → See admin dashboard!

---

**Last Updated:** January 2025  
**Version:** 2.0.0  
**Status:** ✅ Production Ready
