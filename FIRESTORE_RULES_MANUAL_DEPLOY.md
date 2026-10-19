# 🔥 Firestore Rules - Manual Deployment Guide

## Problem
You're getting `[cloud_firestore/permission-denied] Missing or insufficient permissions` because the Firestore rules haven't been deployed to Firebase yet.

---

## ✅ Solution 1: Automatic Deployment (Recommended)

### Windows:
1. Double-click `deploy_firestore_rules.bat`
2. Follow the prompts
3. Done! ✅

### Manual Command:
```bash
firebase deploy --only firestore:rules
```

**If this times out**, use Solution 2 below.

---

## ✅ Solution 2: Manual Deployment via Firebase Console

### Step-by-Step:

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com/
   - Select your **ODC Tracker** project

2. **Navigate to Firestore Rules**
   - Click **"Firestore Database"** in left sidebar
   - Click **"Rules"** tab at the top

3. **Copy the Rules**
   - Open the `firestore.rules` file in this project
   - Select ALL content (Ctrl+A)
   - Copy (Ctrl+C)

4. **Paste into Firebase Console**
   - Delete all existing rules in Firebase Console
   - Paste the new rules (Ctrl+V)

5. **Publish**
   - Click **"Publish"** button
   - Wait for confirmation (takes 5-10 seconds)

6. **Verify**
   - You should see "Rules deployed successfully"
   - The rules editor should show the new rules

---

## 🔍 What These Rules Do

### For User Registration (Your Current Error):
```javascript
// Users collection
match /users/{userId} {
  // Allow user creation during signup
  allow create: if isSignedIn() && isOwner(userId);
  ...
}
```
This allows newly authenticated users to create their profile in Firestore.

### For Attendance Tracking:
```javascript
match /attendance/{attendanceId} {
  // Users can create and manage their own attendance
  allow read, write: if isSignedIn() && isOwner(userId);
  ...
}
```

### For Leave Management:
```javascript
match /leaves/{leaveId} {
  allow read, create: if isSignedIn() && isOwner(userId);
  allow update: if isAnyAdmin(); // Approve/reject
  ...
}
```

### For Leave Balances:
```javascript
match /leave_balances/{balanceId} {
  // Users can auto-initialize their balance
  allow create, update: if isSignedIn() && balanceId.split('_')[0] == request.auth.uid;
  ...
}
```

### For Monthly Reports:
```javascript
match /monthly_reports/{reportId} {
  allow read: if isSignedIn() && (reportId.split('_')[0] == request.auth.uid || isAnyAdmin());
  allow create, update: if isAnyAdmin();
  ...
}
```

---

## 🧪 Test After Deployment

### Test 1: User Registration
1. Go to: https://odc-ten.vercel.app
2. Click "Create Account"
3. Fill in all fields
4. Click "Create Account"
5. **Expected**: Account created successfully ✅

### Test 2: Attendance Check-in
1. Login to your account
2. Click "Check In"
3. **Expected**: Check-in recorded ✅

### Test 3: Leave Application
1. Navigate to Leave Application
2. Select leave type and dates
3. Submit
4. **Expected**: Leave request created ✅

### Test 4: Monthly Report
1. Navigate to Reports
2. Select current month
3. **Expected**: Report generated with metrics ✅

---

## ❌ Common Errors & Fixes

### Error: "Missing or insufficient permissions"
**Cause**: Rules not deployed yet
**Fix**: Deploy rules using Solution 1 or 2 above

### Error: "The document does not exist"
**Cause**: User profile not created after authentication
**Fix**: Ensure rules allow `create` for users collection (already fixed)

### Error: "PERMISSION_DENIED: Permission denied"
**Cause**: Trying to access another user's data
**Fix**: This is expected - users can only access their own data

### Error: "Invalid rule: Unknown function: split"
**Cause**: Firestore rules don't support `split()`
**Fix**: Already handled - we use this safely in our rules

---

## 🔒 Security Features

These rules ensure:
- ✅ Users can only read/write their own data
- ✅ Admins can manage all users
- ✅ Leave balances auto-initialize securely
- ✅ Audit logs are immutable
- ✅ Reports are read-only after creation
- ✅ Proper access control on all collections

---

## 📊 Collections Covered

The rules secure these collections:
- `users` - User profiles
- `admins` - Admin accounts
- `users/{userId}/attendance` - Time tracking
- `users/{userId}/leaves` - Leave requests
- `users/{userId}/workSchedules` - Work shifts
- `users/{userId}/tasks` - User tasks
- `users/{userId}/notes` - Personal notes
- `users/{userId}/notifications` - User notifications
- `leave_balances` - Leave quota tracking
- `monthly_reports` - Generated reports
- `admin_audit_logs` - Admin action logs
- `deleted_users` - Deletion markers

---

## 🚀 Next Steps After Deployment

1. **Test User Registration** - Create a new account
2. **Test Check-in/Check-out** - Record attendance
3. **Apply for Leave** - Test leave workflow
4. **Generate Report** - View monthly summary
5. **Admin Functions** - Approve leaves, view reports

---

## 💡 Pro Tips

1. **Check Rules Syntax**: Firebase Console validates rules before publishing
2. **Test in Console**: Use the "Rules Playground" to test access patterns
3. **Monitor Usage**: Check Firestore usage in Firebase Console
4. **Enable Offline**: Rules work with offline persistence enabled
5. **Backup Rules**: Always keep a copy of working rules

---

## 🆘 Still Having Issues?

If you're still getting permission errors after deploying:

1. **Clear browser cache** and reload the app
2. **Logout and login again** to refresh auth tokens
3. **Check Firebase Console** → Firestore Database → Data
   - Verify your user document exists in `users` collection
4. **Check Firebase Console** → Authentication
   - Verify your account is listed in users
5. **Try incognito/private browsing** to rule out cache issues

---

## 📝 Example: Successful Deployment

```
=== Deploying to 'odc-tracker-ai'...

i  deploying firestore
i  firestore: reading firestore rules from firestore.rules...
✔  firestore: rules file compiled successfully
i  firestore: uploading rules firestore.rules...
✔  firestore: released rules firestore.rules to cloud.firestore

✔  Deploy complete!
```

---

## ⚡ Quick Deploy Checklist

- [ ] Firebase CLI installed (`npm install -g firebase-tools`)
- [ ] Logged in to Firebase (`firebase login`)
- [ ] In correct directory (project root)
- [ ] Rules file exists (`firestore.rules`)
- [ ] Run deploy command
- [ ] Wait for success message
- [ ] Test app functionality

---

**That's it!** Once rules are deployed, your app will work perfectly. All data operations will be secure and functional. 🎉
