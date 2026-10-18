# ✅ Testing Checklist - Admin Login & Profile

## Before Testing

### 1. Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### 2. Verify Admin User in Firebase

**Firebase Authentication:**
- Email: `0000011111@odctracker.app`
- Password: `12345678`
- Copy the UID

**Firestore Database:**
- Collection: `users`
- Document ID: (the UID from Auth)
- **Critical field**: `role: "admin"` (must be lowercase string)

---

## Testing Steps

### Step 1: Clean Build
```bash
# Clean previous build
flutter clean

# Get dependencies
flutter pub get

# Rebuild
flutter build apk --debug
# OR for running on device
flutter run
```

### Step 2: Test Login

1. **Open the app**
2. **Enter credentials:**
   - Mobile: `0000011111`
   - Password: `12345678`
3. **Click Login**

**Expected Result:**
- ✅ Login successful
- ✅ Navigates to main screen
- ✅ No error messages

**If fails:**
- Check Firebase Console → Authentication (user exists?)
- Check email format is `0000011111@odctracker.app`
- Check password is `12345678`

---

### Step 3: Verify Profile Screen

After login, **tap Profile tab** (5th icon from left)

**Expected Result:**
- ✅ Profile header shows "Admin User"
- ✅ Shows mobile number: 0000011111
- ✅ Shows Employee ID: ADMIN001
- ✅ Schedule banner shows "Schedule A" or "Schedule B"
- ✅ All settings sections visible
- ✅ Theme selector works
- ✅ Sign Out button at bottom

**If profile is blank:**
- Check Firestore document exists with correct UID
- Check all required fields are present
- Check `role` field is set to `admin`
- Restart app (force close and reopen)

---

### Step 4: Verify Admin Tab

Look at the **bottom navigation bar**

**Expected Result:**
- ✅ **6 tabs** total (not 5)
- ✅ Tabs from left to right:
  1. 📊 Today
  2. 📅 Calendar
  3. 📈 Reports
  4. ✓ Tasks
  5. 👤 Profile
  6. ⚙️ Admin ← **THIS IS NEW!**

**If Admin tab missing:**
- Check Firestore `role` field = `admin` (lowercase!)
- Force close app and reopen
- Check Firebase Console for the document

---

### Step 5: Test Admin Dashboard

**Tap the Admin tab** (6th icon, gear/settings icon)

**Expected Result:**
- ✅ Admin Dashboard loads
- ✅ Shows stats cards:
  - Total Users
  - Active Users
  - Disabled Users
  - Admin Users
- ✅ Bottom navigation with 5 tabs:
  1. Dashboard
  2. Users
  3. Analytics
  4. Audit Logs
  5. Settings

**If dashboard blank or crashes:**
- Check console for errors
- Check Firestore rules are deployed
- Verify `role: "admin"` in user document

---

### Step 6: Test User Management

In Admin Dashboard, **tap Users tab**

**Expected Result:**
- ✅ Shows list of all users
- ✅ Can search users
- ✅ Can filter by role/status
- ✅ Tap a user → User Detail Screen
- ✅ Can view user's attendance, tasks, notes

---

### Step 7: Test User Detail & Delete

1. **Tap on a user** from Users list
2. **Scroll down** to Danger Zone
3. **Tap "Delete User"** button

**Expected Result:**
- ✅ First confirmation dialog appears
- ✅ Shows what will be deleted
- ✅ After confirming, second dialog asks to type "DELETE"
- ✅ After typing DELETE, user is deleted
- ✅ Success message shown
- ✅ Navigates back to user list

**If delete fails:**
- Check Firestore rules deployed
- Check admin has proper role
- Check network connection

---

### Step 8: Test Audit Logs

In Admin Dashboard, **tap Audit Logs tab**

**Expected Result:**
- ✅ Shows list of admin actions
- ✅ Each log shows:
  - Action type (Delete User, Update User, etc.)
  - Admin who performed it
  - Target user
  - Timestamp
- ✅ Can filter by action type
- ✅ Color-coded (Red for delete, Blue for update, etc.)

---

## Common Issues & Solutions

### Issue 1: Profile screen blank

**Symptoms:**
- Login works but profile shows nothing
- No name, no settings

**Solution:**
```
1. Check Firebase Console → Firestore
2. Verify users/{UID} document exists
3. Check all 16 fields are present
4. Verify Document ID = Auth UID (must match exactly!)
5. Restart app
```

### Issue 2: Admin tab not showing

**Symptoms:**
- Only 5 tabs at bottom
- No Admin/Settings 6th tab

**Solution:**
```
1. Open Firebase Console → Firestore
2. Navigate to users/{UID}
3. Find "role" field
4. Change to "admin" (lowercase, no quotes in value)
5. Force close app
6. Reopen app and login again
```

### Issue 3: Admin dashboard crashes

**Symptoms:**
- App crashes when tapping Admin tab
- Error in console

**Solution:**
```
1. Check Firestore rules deployed:
   firebase deploy --only firestore:rules

2. Verify admin user document has:
   - role: "admin"
   - All required fields

3. Check console for specific error
4. Restart app
```

### Issue 4: Can't delete users

**Symptoms:**
- Delete button doesn't work
- Permission denied error

**Solution:**
```
1. Deploy Firestore rules:
   firebase deploy --only firestore:rules

2. Verify admin role:
   - Open Firestore
   - Check users/{UID}/role = "admin"

3. Check admin_audit_logs collection exists
4. Check deleted_users collection exists
```

### Issue 5: Can't login

**Symptoms:**
- "Wrong password" or "User not found"

**Solution:**
```
1. Firebase Console → Authentication
2. Check user exists with email: 0000011111@odctracker.app
3. Reset password if needed
4. Verify email format (must include @odctracker.app)
```

---

## Verification Checklist

After all tests, verify:

- [ ] Can login with 0000011111 / 12345678
- [ ] Profile screen shows "Admin User"
- [ ] All profile settings visible and working
- [ ] 6 tabs at bottom (including Admin)
- [ ] Admin tab shows dashboard with stats
- [ ] Can view Users list
- [ ] Can view user details
- [ ] Can delete users (with double confirmation)
- [ ] Deletion creates audit log
- [ ] Audit Logs tab shows deletion
- [ ] Can logout successfully
- [ ] Can login again after logout

---

## Performance Check

- [ ] App loads in < 3 seconds
- [ ] Profile loads in < 2 seconds
- [ ] Admin dashboard loads in < 2 seconds
- [ ] User list loads in < 3 seconds
- [ ] No lag when switching tabs
- [ ] No memory leaks (check in DevTools)

---

## Final Validation

Run these commands:

```bash
# 1. Analyzer (should have no errors in lib/)
flutter analyze lib/

# 2. Build APK (should succeed)
flutter build apk --release

# 3. Run on device
flutter run --release
```

**All should complete without errors!**

---

## Success Criteria

✅ **Profile Screen:**
- Shows user info
- All settings work
- Theme switching works
- Logout works

✅ **Admin Features:**
- Admin tab visible
- Dashboard loads
- User management works
- Audit logs visible
- Can delete users

✅ **No Errors:**
- No console errors
- No crashes
- No blank screens
- All data loads

---

## If Everything Works

🎉 **Congratulations!** Your admin system is fully functional!

You can now:
- Manage users from admin panel
- View analytics and reports
- Track all admin actions via audit logs
- Delete users with full audit trail
- Monitor ODC time tracking

**Next steps:**
1. Deploy Firestore rules to production
2. Create additional admin users if needed
3. Set up Cloud Function for complete Auth deletion (optional)
4. Monitor audit logs regularly

---

## Need Help?

If you still have issues:

1. Check `ADMIN_SETUP_INSTRUCTIONS.md` for detailed setup
2. Check `docs/FIREBASE_ADMIN_SETUP.md` for Firebase guide
3. Check `docs/ADMIN_DELETION_AUDIT_GUIDE.md` for admin features
4. Check Firebase Console logs for errors
5. Run `flutter doctor` to check Flutter installation

**GitHub Repository:** All code is committed and pushed to main branch
