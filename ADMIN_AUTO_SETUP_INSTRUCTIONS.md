# 🚀 Automated Admin Setup - Instructions

## Easy Way: Run Setup Script Directly

I've created an automated setup script that will create the admin account for you!

### Option 1: Run Via Terminal (Easiest)

```bash
# In your project directory
flutter run -d chrome lib/setup_admin.dart
```

Or for web:
```bash
flutter run -d web-server lib/setup_admin.dart
```

### Option 2: Modify main.dart Temporarily

1. **Open `lib/main.dart`**

2. **Add import at the top:**
   ```dart
   import 'setup_admin.dart';
   ```

3. **Add this right after Firebase.initializeApp:**
   ```dart
   // RUN ONCE ONLY - Remove after admin is created!
   await setupAdminAccount();
   return; // Stop here
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

5. **Check the console output** - You'll see:
   ```
   ═══════════════════════════════════════════════════════
   🎉 ADMIN ACCOUNT SETUP COMPLETE!
   ═══════════════════════════════════════════════════════
   
   Login Credentials:
     Username: admin
     Password: Admin@123456
     Email: admin@admin.odctracker.app
     UID: [your-uid-here]
   ```

6. **Remove the setup code** from main.dart

7. **Test admin login!**

## What the Script Does

The script automatically:

✅ Creates Firebase Auth account
- Email: `admin@admin.odctracker.app`
- Password: `Admin@123456`

✅ Creates Firestore document in `admins` collection with all required fields:
- username: admin
- fullName: Super Admin  
- email: admin@admin.odctracker.app
- phoneNumber: +91 9999999999
- permissions: ['full_access']
- isActive: true
- isSuperAdmin: true
- createdAt: (current timestamp)
- updatedAt: (current timestamp)
- lastLogin: null

✅ Verifies the setup worked

✅ Shows you the login credentials

## After Setup

1. **Go to your app**
2. **Click "Admin Login"**
3. **Enter:**
   - Username: `admin`
   - Password: `Admin@123456`
4. **Click "Login as Admin"**
5. **✅ You're in!** - Admin tab will appear in navigation

## Troubleshooting

### "Email already in use"
The script handles this! It will:
- Log in with existing account
- Check if Firestore document exists
- Create it if missing
- Show you the existing UID

### "Permission denied"
Make sure Firestore rules are deployed:
```bash
firebase deploy --only firestore:rules
```

### "Firebase not initialized"
The script initializes Firebase automatically. If you see this error, make sure `firebase_options.dart` exists.

## Security Note

⚠️ **Change the password immediately after first login!**

The default password `Admin@123456` is only for initial setup.

## Manual Alternative

If you prefer to create manually, see `ADMIN_QUICK_SETUP.md` for step-by-step Firebase Console instructions.

---

**Created:** setup_admin.dart  
**Purpose:** Automated admin account creation  
**Run:** Once only during initial setup
