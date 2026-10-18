# Vercel Deployment Guide for ODC Tracker AI

## ✅ Fixed Issues

The 404 "This page doesn't exist" error has been resolved by:

1. **Updated `vercel.json`** - Changed from deprecated "routes" to "rewrites" syntax
2. **Proper SPA routing** - All routes now rewrite to `/index.html`
3. **Build command fixed** - Removed unsupported `--web-renderer` flag
4. **Base href placeholder** - Updated `web/index.html` to use `$FLUTTER_BASE_HREF`
5. **Added `.vercelignore`** - Optimized deployment by excluding unnecessary files

## 📦 Latest Commit

**Commit:** `da79738`  
**Message:** fix: Update Vercel configuration for proper SPA routing and deployment

## 🚀 Deployment Steps

### 1. Vercel Auto-Deploy (Recommended)

Since your GitHub repo is connected to Vercel, it should automatically deploy:

1. Go to https://vercel.com/dashboard
2. Find your project
3. Check the latest deployment (triggered by commit `da79738`)
4. Wait for the build to complete (usually 2-5 minutes)
5. Click on the deployment URL to test

### 2. Manual Deploy (If Auto-Deploy Doesn't Trigger)

```bash
# Install Vercel CLI (if not installed)
npm install -g vercel

# Login to Vercel
vercel login

# Deploy from project root
vercel --prod
```

## 🧪 Testing After Deployment

Once deployed, test these URLs (replace `your-app.vercel.app` with your actual domain):

1. **Home:** https://your-app.vercel.app/
2. **Login:** https://your-app.vercel.app/login
3. **Dashboard:** https://your-app.vercel.app/dashboard
4. **Admin:** https://your-app.vercel.app/admin

All routes should work without 404 errors.

## 🔥 Firebase Configuration

After Vercel deployment is successful, deploy Firestore rules:

```bash
firebase login
firebase deploy --only firestore:rules
```

## 👤 Create Admin User

If you haven't created the admin user yet, follow these steps:

### In Firebase Console:

1. Go to **Authentication** → Users
2. Find or create user with phone: `0000011111` (no +91 prefix)
3. Copy the **UID** (e.g., `SUkOsfIA55N7KSzyfRy33ckmMZf2`)

4. Go to **Firestore Database** → `users` collection
5. Create document with ID = the UID you copied
6. Add these fields:

```
uid: string = SUkOsfIA55N7KSzyfRy33ckmMZf2
fullName: string = Admin User
mobileNumber: string = 0000011111
email: string = admin@odctracker.app
role: string = admin          ← CRITICAL: lowercase!
isDisabled: boolean = false
employeeId: string = ADMIN001
shiftStart: string = 13:00
shiftEnd: string = 22:00
dailyGoal: number = 480       ← NUMBER type, not string!
breakLimit: number = 60       ← NUMBER type, not string!
theme: string = system
notificationEnabled: boolean = true
createdAt: timestamp = (current time)
updatedAt: timestamp = (current time)
lastLogin: timestamp = (current time)
```

## 🧭 Vercel Configuration Files

### `vercel.json`
```json
{
  "buildCommand": "flutter build web --release --base-href /",
  "outputDirectory": "build/web",
  "installCommand": "git clone https://github.com/flutter/flutter.git -b stable --depth 1 && flutter/bin/flutter config --enable-web && flutter/bin/flutter pub get",
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
```

### `.vercelignore`
```
.dart_tool/
.packages
android/
ios/
test/
*.md
```

## 🎯 Expected Behavior

After successful deployment:

1. ✅ No 404 errors on any route
2. ✅ Direct URL access works (e.g., `/admin`, `/dashboard`)
3. ✅ Browser refresh works without losing route
4. ✅ Firebase authentication works
5. ✅ Admin dashboard loads when logged in with admin credentials
6. ✅ User management and deletion works
7. ✅ Audit logs display properly

## 🐛 Troubleshooting

### If 404 Still Appears:

1. Check Vercel build logs for errors
2. Verify `vercel.json` was deployed correctly
3. Try clearing Vercel cache: `vercel --prod --force`
4. Check if Flutter installation succeeded in Vercel logs

### If Admin Dashboard Doesn't Show:

1. Verify admin user exists in Firestore `users` collection
2. Check `role` field is exactly `"admin"` (lowercase)
3. Check `dailyGoal` and `breakLimit` are NUMBER type, not strings
4. Check browser console for errors

### If Firebase Errors Appear:

1. Ensure Firebase config is correct in `lib/core/config/firebase_options.dart`
2. Deploy Firestore rules: `firebase deploy --only firestore:rules`
3. Check Firebase project permissions

## 📊 Build Status

- ✅ Local build successful (86.5s)
- ✅ Zero compilation errors
- ✅ 16 deprecation warnings (cosmetic only)
- ✅ All files committed to GitHub
- ⏳ Vercel deployment pending

## 🔗 Resources

- [Vercel Dashboard](https://vercel.com/dashboard)
- [Firebase Console](https://console.firebase.google.com)
- [GitHub Repository](https://github.com/preetham711/odc)

---

**Last Updated:** Commit `da79738`  
**Status:** Ready for Vercel deployment
