# 📝 Manual Firestore Setup - Copy & Paste Guide

## Your Admin UID
```
SUkOsfIA55N7KSzyfRy33ckmMZf2
```

## Step-by-Step Instructions

### 1. Open Firebase Console
- Go to: https://console.firebase.google.com
- Select your project: **odc-tracker**
- Click: **Firestore Database** (left sidebar)

### 2. Navigate to Users Collection
- Click on **`users`** collection
- If it doesn't exist, click **"+ Start collection"** and name it `users`

### 3. Add Document
- Click **"+ Add document"**
- Document ID: `SUkOsfIA55N7KSzyfRy33ckmMZf2` (paste this)

### 4. Add Each Field (Copy-Paste Values)

Click **"+ Add field"** for each field below:

#### String Fields (Type: string)

| Field Name | Value to Paste |
|------------|----------------|
| `uid` | `SUkOsfIA55N7KSzyfRy33ckmMZf2` |
| `fullName` | `Admin User` |
| `mobileNumber` | `0000011111` |
| `email` | `admin@odctracker.app` |
| `role` | `admin` |
| `employeeId` | `ADMIN001` |
| `shiftStart` | `13:00` |
| `shiftEnd` | `22:00` |
| `theme` | `system` |

#### Number Fields (Type: number)

| Field Name | Value to Paste |
|------------|----------------|
| `dailyGoal` | `480` |
| `breakLimit` | `60` |

#### Boolean Fields (Type: boolean)

| Field Name | Value to Select |
|------------|-----------------|
| `isDisabled` | ☐ false |
| `notificationEnabled` | ☑ true |

#### Timestamp Fields (Type: timestamp)

| Field Name | Action |
|------------|--------|
| `createdAt` | Click calendar icon → "Set to current time" |
| `updatedAt` | Click calendar icon → "Set to current time" |
| `lastLogin` | Click calendar icon → "Set to current time" |

### 5. Save
- Click **"Save"** button at the bottom

### 6. Verify
After saving, you should see a document that looks like this:

```
users/SUkOsfIA55N7KSzyfRy33ckmMZf2
├── uid: "SUkOsfIA55N7KSzyfRy33ckmMZf2"
├── fullName: "Admin User"
├── mobileNumber: "0000011111"
├── email: "admin@odctracker.app"
├── role: "admin"                    ← CRITICAL!
├── isDisabled: false
├── employeeId: "ADMIN001"
├── shiftStart: "13:00"
├── shiftEnd: "22:00"
├── dailyGoal: 480
├── breakLimit: 60
├── theme: "system"
├── notificationEnabled: true
├── createdAt: October 17, 2026 at ...
├── updatedAt: October 17, 2026 at ...
└── lastLogin: October 17, 2026 at ...
```

## ✅ Test Login

1. **Restart your app** (force close and reopen)
2. **Login** with:
   - Mobile: `0000011111`
   - Password: `12345678`
3. **Expected Results**:
   - ✅ Profile screen loads with "Admin User"
   - ✅ Bottom navigation shows **6 tabs** (last one is "Admin")
   - ✅ Tapping Admin tab shows admin dashboard
   - ✅ Can see user management, analytics, audit logs

## 🐛 Troubleshooting

### Profile still blank?
- **Check**: Document ID = `SUkOsfIA55N7KSzyfRy33ckmMZf2` (must match Auth UID exactly)
- **Fix**: Delete document and recreate with correct UID

### Admin tab not showing?
- **Check**: `role` field = `admin` (lowercase, no spaces)
- **Fix**: Edit document, change `role` to `admin`

### Can't login?
- **Check**: Firebase Auth has user with email `0000011111@odctracker.app`
- **Fix**: Go to Authentication → Users → verify email is correct

### Still having issues?
1. Check Firestore rules are deployed: `firebase deploy --only firestore:rules`
2. Verify all 16 fields are present
3. Check Firebase Console errors
4. Try logging out and back in

## 🎯 Quick Copy-Paste for Each Field

### For Copy-Paste Efficiency:

**Field 1-9** (strings):
```
uid
SUkOsfIA55N7KSzyfRy33ckmMZf2

fullName
Admin User

mobileNumber
0000011111

email
admin@odctracker.app

role
admin

employeeId
ADMIN001

shiftStart
13:00

shiftEnd
22:00

theme
system
```

**Field 10-11** (numbers):
```
dailyGoal
480

breakLimit
60
```

**Field 12-13** (booleans):
- `isDisabled`: false
- `notificationEnabled`: true

**Field 14-16** (timestamps):
- `createdAt`: Click "Set to current time"
- `updatedAt`: Click "Set to current time"  
- `lastLogin`: Click "Set to current time"

---

## 🎉 You're Done!

After completing these steps:
1. Admin user exists in Firebase Auth ✅
2. Admin profile exists in Firestore ✅
3. All required fields are populated ✅
4. Can login and use admin features ✅

**Time to complete**: 5 minutes
**Difficulty**: Easy (just copy-paste!)
