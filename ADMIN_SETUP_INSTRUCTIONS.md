# 🔧 Admin User Setup - Quick Fix

## Problem
When you login with `0000011111` / `12345678`:
- ❌ Admin dashboard not showing
- ❌ Profile screen not showing
- ❌ User data not in Firestore properly

## Root Cause
The admin user doesn't exist in Firebase yet, or exists in Firebase Auth but not in Firestore with `role: 'admin'`.

---

## ✅ Solution: Create Admin User Manually in Firebase Console

### Step 1: Create Admin in Firebase Authentication

1. Go to **Firebase Console**: https://console.firebase.google.com
2. Select your project
3. Go to **Authentication** → **Users** tab
4. Click **Add User**
5. Enter:
   - **Email**: `0000011111@odctracker.app`
   - **Password**: `12345678`
6. Click **Add User**
7. **Copy the User UID** (you'll need it in Step 2)

---

### Step 2: Create Admin Profile in Firestore

1. In Firebase Console, go to **Firestore Database**
2. Click **+ Start collection**
3. Collection ID: `users`
4. Click **Next**
5. Document ID: **Paste the UID from Step 1**
6. Add these fields **exactly**:

```
Field               | Type      | Value
--------------------|-----------|----------------------------------
uid                 | string    | (same as document ID)
fullName            | string    | Admin User
mobileNumber        | string    | 0000011111
email               | string    | admin@odctracker.app
role                | string    | admin
isDisabled          | boolean   | false
employeeId          | string    | ADMIN001
createdAt           | timestamp | (click "Set to current time")
updatedAt           | timestamp | (click "Set to current time")
lastLogin           | timestamp | (click "Set to current time")
shiftStart          | string    | 13:00
shiftEnd            | string    | 22:00
dailyGoal           | number    | 480
breakLimit          | number    | 60
theme               | string    | system
notificationEnabled | boolean   | true
```

7. Click **Save**

---

### Step 3: Test Admin Login

1. Open your app
2. Login with:
   - **Mobile**: `0000011111`
   - **Password**: `12345678`
3. You should now see:
   - ✅ Profile screen with "Admin User" name
   - ✅ 6th tab "Admin" in bottom navigation
   - ✅ Admin dashboard when you tap Admin tab

---

## 🔄 Alternative: Use the Setup Script

If you prefer automated setup:

```bash
cd scripts
dart setup_admin_user.dart
```

**Note:** The script requires `firebase_admin` package which needs special setup. The manual method above is faster.

---

## ✅ Verification Checklist

After setup, verify:
- [ ] Can login with 0000011111 / 12345678
- [ ] Profile screen shows "Admin User"
- [ ] Bottom navigation has 6 tabs (Today, Calendar, Reports, Tasks, Profile, **Admin**)
- [ ] Clicking Admin tab shows admin dashboard
- [ ] Admin dashboard shows user stats
- [ ] Can navigate to Users, Analytics, Audit Logs, Settings

---

## 🐛 Troubleshooting

### Issue: Profile screen blank
**Cause:** Firestore document missing or wrong UID  
**Fix:** Verify document ID in Firestore matches Auth UID exactly

### Issue: Admin tab not showing
**Cause:** `role` field is not set to `'admin'` (case-sensitive!)  
**Fix:** Edit Firestore document, set `role: 'admin'` (lowercase)

### Issue: Can't login
**Cause:** Wrong email format in Auth  
**Fix:** Email MUST be `0000011111@odctracker.app` (app derives email from mobile)

### Issue: Data not saving
**Cause:** Firestore rules not deployed  
**Fix:** Run `firebase deploy --only firestore:rules`

---

## 📋 Quick Copy-Paste for Firestore

```json
{
  "uid": "PASTE_AUTH_UID_HERE",
  "fullName": "Admin User",
  "mobileNumber": "0000011111",
  "email": "admin@odctracker.app",
  "role": "admin",
  "isDisabled": false,
  "employeeId": "ADMIN001",
  "createdAt": "CURRENT_TIMESTAMP",
  "updatedAt": "CURRENT_TIMESTAMP",
  "lastLogin": "CURRENT_TIMESTAMP",
  "shiftStart": "13:00",
  "shiftEnd": "22:00",
  "dailyGoal": 480,
  "breakLimit": 60,
  "theme": "system",
  "notificationEnabled": true
}
```

---

## 🎯 Expected Result

After successful setup:

**Login → See 6 tabs → Tap Admin → Admin Dashboard with:**
- Total Users count
- Active Users today
- Real-time stats
- User management
- Audit logs
- Analytics
- Settings

**Profile screen shows:**
- Name: Admin User
- Mobile: 0000011111
- Employee ID: ADMIN001
- Schedule settings
- All profile options working

---

## Need Help?

If still not working:
1. Check Firebase Console → Authentication → Users (is user there?)
2. Check Firebase Console → Firestore → users collection (is document there?)
3. Check document UID matches Auth UID
4. Check `role` field is exactly `admin` (lowercase)
5. Restart app after making changes
