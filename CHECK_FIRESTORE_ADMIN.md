# ⚠️ CRITICAL: Check Your Firestore Admin Document

## The Issue

If Admin tab is not showing, it's because:
1. **Firestore document doesn't exist**, OR
2. **`role` field is not set to `"admin"`**, OR  
3. **`role` field has wrong type or value**

---

## ✅ Step-by-Step Verification

### 1. Open Firebase Console
Go to: https://console.firebase.google.com

### 2. Navigate to Firestore
1. Select your project
2. Click **Firestore Database** (left sidebar)
3. Click on **`users`** collection

### 3. Find Your Admin User
Look for document with ID: `SUkOsfIA55N7KSzyfRy33ckmMZf2`

**If you don't see it:**
- The document doesn't exist
- You need to create it (follow `MANUAL_FIRESTORE_STEPS.md`)

### 4. Open the Document
Click on the document ID to view fields

### 5. Verify the `role` Field

**MUST BE EXACTLY:**
```
Field name:  role
Type:        string
Value:       admin
```

**Common Mistakes:**
- ❌ `role: "Admin"` (capital A)
- ❌ `role: "ADMIN"` (all caps)
- ❌ `role: "user"` (wrong value)
- ❌ Field named `Role` (capital R)
- ❌ Type is `number` or `boolean`

**CORRECT:**
- ✅ `role: "admin"` (lowercase, string type)

### 6. Check All Required Fields

The document MUST have these 16 fields:

```
✅ uid (string)
✅ fullName (string)
✅ mobileNumber (string)
✅ email (string)
✅ role (string) = "admin"  ⚠️ CRITICAL
✅ isDisabled (boolean) = false
✅ employeeId (string)
✅ shiftStart (string)
✅ shiftEnd (string)
✅ dailyGoal (number) = 480  ⚠️ Must be NUMBER not string
✅ breakLimit (number) = 60  ⚠️ Must be NUMBER not string
✅ theme (string)
✅ notificationEnabled (boolean)
✅ createdAt (timestamp)
✅ updatedAt (timestamp)
✅ lastLogin (timestamp)
```

---

## 🔧 How to Fix

### If Document Doesn't Exist:
1. Follow `MANUAL_FIRESTORE_STEPS.md`
2. Create all 16 fields
3. Document ID must match Auth UID: `SUkOsfIA55N7KSzyfRy33ckmMZf2`

### If `role` Field is Wrong:
1. Click on the `role` field
2. Click **Edit field**
3. Change value to: `admin` (lowercase)
4. Ensure type is **string**
5. Click **Update**

### If Types are Wrong:
1. **dailyGoal** must be type **number** (not string!) → value: 480
2. **breakLimit** must be type **number** (not string!) → value: 60
3. **isDisabled** must be type **boolean** → value: false
4. **notificationEnabled** must be type **boolean** → value: true

---

## 🧪 Test After Fixing

1. **Save changes in Firestore**
2. **Force close your app** (don't just restart)
3. **Reopen the app**
4. **Login with** 0000011111 / 12345678
5. **Check bottom navigation**

**Expected:** You should see **6 tabs** (last one is "Admin")

---

## 📊 Debugging

### Check Debug Console

After you've added debug logging, run the app and watch the console output:

```bash
flutter run
```

Look for these messages:
```
✅ Profile loaded: Admin User, role: admin, isAdmin: true
=== USER PROFILE DATA ===
User: Admin User
Role: admin
isAdmin: true
========================
Admin check result: true
Building MainLayout with isAdmin: true
Nav items count: 6
```

**If you see:**
```
Role: user
isAdmin: false
```
→ Fix the `role` field in Firestore!

**If you see:**
```
❌ Error loading user profile: ...
```
→ Document doesn't exist or Firestore rules not deployed

---

## 🎯 Final Checklist

Before restarting app:

- [ ] Firestore document exists with correct UID
- [ ] `role` field is `"admin"` (lowercase, string)
- [ ] `dailyGoal` is NUMBER (480)
- [ ] `breakLimit` is NUMBER (60)
- [ ] All 16 fields present
- [ ] Firestore rules deployed (`firebase deploy --only firestore:rules`)
- [ ] App force closed (not just hot restarted)

---

## 💡 Quick Test

To quickly test if your Firestore document is correct, try this:

1. Open Firebase Console → Firestore
2. Find your admin document
3. Right-click → **Export document**
4. Compare with `FIRESTORE_ADMIN_DATA.json` in your project

They should match exactly (except timestamps and UID).

---

## Still Not Working?

If admin tab still doesn't show after:
1. ✅ Fixing Firestore document
2. ✅ Deploying rules
3. ✅ Force closing app
4. ✅ Logging in again

Then:
1. Check the debug console output
2. Look for the "isAdmin" value in logs
3. Share the logs for further debugging
