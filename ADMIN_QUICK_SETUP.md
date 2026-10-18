# Admin Login - Quick Setup Guide

## ⚠️ IMPORTANT: Current Status

The admin login is showing "Missing or insufficient permissions" because:
1. ✅ Code is ready
2. ❌ Firestore rules need to be deployed
3. ❌ Admin account needs to be created in Firebase

## 🚀 Quick Setup (5 Minutes)

### Step 1: Deploy Firestore Rules

Open terminal and run:
```bash
firebase login
firebase deploy --only firestore:rules
```

If you don't have Firebase CLI installed:
```bash
npm install -g firebase-tools
firebase login
firebase deploy --only firestore:rules
```

### Step 2: Create Admin Account in Firebase Console

1. **Go to Firebase Console:** https://console.firebase.google.com

2. **Select your project**

3. **Create Firebase Auth User:**
   - Go to **Authentication** → **Users**
   - Click **Add User**
   - Email: `admin@admin.odctracker.app`
   - Password: `Admin@123456` (or your choice - min 6 characters)
   - Click **Add User**
   - **COPY THE UID** (important!)

4. **Create Firestore Document:**
   - Go to **Firestore Database**
   - Click **Start collection**
   - Collection ID: `admins`
   - Click **Next**
   
   - Document ID: **PASTE THE UID YOU COPIED**
   - Add these fields one by one:

   | Field Name | Field Type | Value |
   |------------|-----------|-------|
   | uid | string | (paste the UID) |
   | username | string | admin |
   | fullName | string | Super Admin |
   | email | string | admin@admin.odctracker.app |
   | phoneNumber | string | +91 9999999999 |
   | permissions | array | (add item: `full_access`) |
   | isActive | boolean | true |
   | isSuperAdmin | boolean | true |
   | createdAt | timestamp | (click timestamp icon) |
   | updatedAt | timestamp | (click timestamp icon) |
   | lastLogin | null | (leave null) |

   - Click **Save**

### Step 3: Test Admin Login

1. Go to your app
2. Click "Admin Login"
3. Enter:
   - Username: `admin`
   - Password: `Admin@123456` (or what you set)
4. Click "Login as Admin"
5. ✅ Should login and show admin dashboard!

## 🎯 Expected Result

After successful login:
- ✅ Redirected to main app
- ✅ Bottom navigation shows "Admin" tab (6 tabs total)
- ✅ Can access all admin features
- ✅ Can view all users
- ✅ Can manage users
- ✅ Can view audit logs

## ❓ Troubleshooting

### Error: "Admin account not found"
- Check that the Firestore document ID matches the Firebase Auth UID exactly
- Make sure the document is in the `admins` collection (not `users`)

### Error: "Missing or insufficient permissions"
- Deploy Firestore rules: `firebase deploy --only firestore:rules`
- Wait 1-2 minutes for rules to propagate

### Error: "This account is not an admin account"
- Check that `isActive` field is boolean `true` (not string "true")
- Verify the document exists in `admins` collection

### Admin tab not showing
- Refresh the app
- Check browser console for errors
- Verify admin document has all required fields

## 📝 Default Admin Credentials

After setup:
- **Username:** admin
- **Password:** Admin@123456 (or what you set)
- **Email:** admin@admin.odctracker.app

⚠️ **Change the password immediately after first login for security!**

## 🔍 Verify Setup

Check these in Firebase Console:

1. **Authentication → Users:**
   - ✅ User with email `admin@admin.odctracker.app` exists
   - ✅ Copy the UID

2. **Firestore Database → admins collection:**
   - ✅ Document exists with ID = the UID
   - ✅ Has field `username: "admin"`
   - ✅ Has field `isActive: true` (boolean)
   - ✅ Has field `isSuperAdmin: true` (boolean)
   - ✅ Has array field `permissions` with item `full_access`

3. **Firestore Rules:**
   - ✅ Rules deployed (check timestamp in Firebase Console)
   - ✅ Rules include `admins` collection

## 🎉 Success!

Once you complete these steps:
1. Admin login will work ✅
2. Admin dashboard will be accessible ✅
3. All admin features will be available ✅
4. Both admin types (users with role + admins collection) will work ✅

---

**Need Help?**
- Check the detailed guide: `ADMIN_SYSTEM_SETUP.md`
- Check Firestore rules: `firestore.rules`
- Check admin service: `lib/services/admin_auth_service.dart`
