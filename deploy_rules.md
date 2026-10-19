# Deploy Firestore Rules Manually

Since `firebase deploy` is timing out, use one of these methods:

## Method 1: Firebase Console (Easiest)

1. **Go to Firebase Console:** https://console.firebase.google.com
2. **Select your project**
3. **Go to Firestore Database**
4. **Click on "Rules" tab**
5. **Copy the contents of `firestore.rules` file**
6. **Paste into the Firebase Console rules editor**
7. **Click "Publish"**

## Method 2: Copy-Paste the Rules

Open `firestore.rules` and copy all the content, then paste it in Firebase Console.

## Important Change Made

Added this line to allow initial admin creation:
```javascript
// Allow authenticated users to create their own admin document (for initial setup)
allow create: if isSignedIn() && isOwner(adminId);
```

This allows the "Create Admin Account" button to work!

## After Deploying Rules

1. Refresh your admin login page
2. Click "Create Admin Account" button
3. Should work now! ✅
