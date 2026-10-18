# Cloud Function Required: Complete User Deletion

## Current Status
✅ **Firestore deletion fully implemented and working**
⚠️ **Firebase Auth deletion requires backend implementation**

## Why Cloud Function is Needed

Firebase Security prevents client-side apps from deleting other users' authentication accounts, even if the client is an admin. This is a security feature to prevent compromised client apps from deleting users.

### Current Behavior
- ✅ All Firestore data is deleted (user document + all subcollections)
- ✅ Audit logs are created
- ✅ Deletion markers are saved
- ⚠️ Firebase Auth account remains (user could potentially re-register with same credentials)

## Implementation Steps

### 1. Setup Firebase Functions

```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Functions in your project
cd your-project-directory
firebase init functions
```

Choose:
- JavaScript or TypeScript (recommend TypeScript)
- Install dependencies with npm

### 2. Create Delete User Function

Create or edit `functions/src/index.ts`:

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

/**
 * Cloud Function to delete a user from Firebase Authentication
 * Only callable by authenticated admins
 */
export const deleteUser = functions.https.onCall(async (data, context) => {
  // Verify caller is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'You must be logged in to call this function'
    );
  }

  const callerUid = context.auth.uid;

  // Verify caller is admin
  const callerDoc = await admin.firestore()
    .collection('users')
    .doc(callerUid)
    .get();

  if (!callerDoc.exists || callerDoc.data()?.role !== 'admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can delete users'
    );
  }

  const targetUid = data.uid;

  if (!targetUid) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'User ID is required'
    );
  }

  // Prevent admin from deleting themselves
  if (targetUid === callerUid) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Cannot delete your own admin account'
    );
  }

  try {
    // Delete user from Firebase Authentication
    await admin.auth().deleteUser(targetUid);

    // Log the deletion (optional, as client already logs to audit)
    await admin.firestore().collection('admin_audit_logs').add({
      adminUid: callerUid,
      adminEmail: context.auth.token.email || 'unknown',
      action: 'delete_user_auth',
      targetUserId: targetUid,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      platform: 'cloud_function',
      metadata: {
        functionName: 'deleteUser',
        source: 'firebase_admin_sdk'
      }
    });

    return { 
      success: true, 
      message: 'User successfully deleted from Firebase Authentication',
      uid: targetUid
    };

  } catch (error: any) {
    console.error('Error deleting user:', error);
    
    if (error.code === 'auth/user-not-found') {
      return {
        success: true,
        message: 'User already deleted from Authentication',
        uid: targetUid
      };
    }

    throw new functions.https.HttpsError(
      'internal',
      `Failed to delete user from Authentication: ${error.message}`
    );
  }
});

/**
 * Optional: Function to batch delete users
 * Useful for cleanup operations
 */
export const batchDeleteUsers = functions.https.onCall(async (data, context) => {
  // Verify caller is authenticated and admin
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  const callerDoc = await admin.firestore()
    .collection('users')
    .doc(context.auth.uid)
    .get();

  if (!callerDoc.exists || callerDoc.data()?.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Admin only');
  }

  const uids: string[] = data.uids || [];

  if (!Array.isArray(uids) || uids.length === 0) {
    throw new functions.https.HttpsError('invalid-argument', 'UIDs array required');
  }

  const results = {
    success: [] as string[],
    failed: [] as { uid: string; error: string }[]
  };

  for (const uid of uids) {
    try {
      await admin.auth().deleteUser(uid);
      results.success.push(uid);
    } catch (error: any) {
      results.failed.push({ uid, error: error.message });
    }
  }

  return results;
});
```

### 3. Deploy Functions

```bash
# Deploy all functions
firebase deploy --only functions

# Or deploy specific function
firebase deploy --only functions:deleteUser
```

### 4. Update Flutter App to Call Cloud Function

Add to `pubspec.yaml`:
```yaml
dependencies:
  cloud_functions: ^4.5.0  # Check for latest version
```

Update `lib/services/admin_service_enhanced.dart`:

```dart
import 'package:cloud_functions/cloud_functions.dart';

class AdminServiceEnhanced {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  // ... existing code ...

  /// Delete user from Firebase Authentication using Cloud Function
  Future<bool> _deleteUserFromAuth(String uid) async {
    try {
      final callable = _functions.httpsCallable('deleteUser');
      final result = await callable.call<Map<String, dynamic>>({
        'uid': uid,
      });

      final data = result.data;
      return data['success'] == true;
    } catch (e) {
      debugPrint('Error calling deleteUser Cloud Function: $e');
      
      // If function doesn't exist or fails, return false
      if (e is FirebaseFunctionsException) {
        debugPrint('Function error code: ${e.code}');
        debugPrint('Function error message: ${e.message}');
      }
      
      return false;
    }
  }

  /// Enhanced deleteUser method with Cloud Function support
  Future<DeleteUserResult> deleteUser(String uid) async {
    try {
      // ... existing Firestore deletion code ...

      // After Firestore deletion, try Auth deletion via Cloud Function
      final authDeleted = await _deleteUserFromAuth(uid);

      if (authDeleted) {
        await _logAuditEvent(
          action: 'delete_user_complete',
          targetUserId: uid,
          metadata: {
            'firestoreDeleted': true,
            'authDeleted': true,
            'method': 'cloud_function'
          },
        );

        return DeleteUserResult(
          success: true,
          message: 'User completely deleted (Firestore + Auth)',
          authDeleted: true,
        );
      } else {
        return DeleteUserResult(
          success: true,
          message: 'User deleted from Firestore. Auth deletion requires Cloud Function deployment.',
          authDeleted: false,
        );
      }
    } catch (e) {
      // ... existing error handling ...
    }
  }
}
```

### 5. Security Considerations

**Function Access Control:**
- ✅ Only authenticated users can call function
- ✅ Only admin role can delete users
- ✅ Admins cannot delete themselves
- ✅ All actions are logged

**Testing:**
```bash
# Test locally with Firebase Emulator
firebase emulators:start --only functions

# In your Flutter app, connect to emulator
FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
```

### 6. Monitoring

After deployment, monitor in Firebase Console:
1. Go to Functions → Dashboard
2. Check invocations, errors, execution time
3. View logs for debugging

### 7. Cost Estimate

Firebase Functions pricing (as of 2024):
- First 2M invocations/month: FREE
- After: $0.40 per million invocations
- Estimated cost for typical usage: < $1/month

## Alternative: Admin SDK Backend

If you have your own backend server, you can use Firebase Admin SDK directly:

```javascript
// Node.js/Express example
const admin = require('firebase-admin');
const express = require('express');

const app = express();

app.post('/api/admin/delete-user', async (req, res) => {
  try {
    // Verify admin token
    const token = req.headers.authorization?.split('Bearer ')[1];
    const decodedToken = await admin.auth().verifyIdToken(token);
    
    // Check admin role
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(decodedToken.uid)
      .get();
    
    if (userDoc.data()?.role !== 'admin') {
      return res.status(403).json({ error: 'Admin only' });
    }

    // Delete user
    const { uid } = req.body;
    await admin.auth().deleteUser(uid);

    res.json({ success: true, message: 'User deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

## Deployment Checklist

- [ ] Firebase Functions initialized in project
- [ ] `deleteUser` Cloud Function created
- [ ] Admin role verification implemented
- [ ] Self-deletion prevention added
- [ ] Error handling implemented
- [ ] Audit logging added
- [ ] Functions deployed to Firebase
- [ ] Flutter app updated to call Cloud Function
- [ ] cloud_functions package added to pubspec.yaml
- [ ] Tested in Firebase Emulator
- [ ] Tested in production with test user
- [ ] Monitoring enabled in Firebase Console
- [ ] Documentation updated

## Testing Plan

1. **Test with Emulator:**
   ```bash
   firebase emulators:start
   ```

2. **Test Cases:**
   - ✅ Admin can delete regular user
   - ✅ Admin cannot delete another admin
   - ✅ Admin cannot delete themselves
   - ✅ Non-admin cannot call function
   - ✅ Unauthenticated user cannot call function
   - ✅ Invalid UID returns proper error
   - ✅ Already deleted user handled gracefully

3. **Production Test:**
   - Create test user
   - Delete via admin panel
   - Verify Auth deletion in Firebase Console
   - Check audit logs
   - Attempt to login with deleted account (should fail)

## Priority
**Medium Priority** - The app is functional without this, but for complete production deployment with proper user management, this should be implemented.

## Estimated Time
- Setup + Implementation: 2-3 hours
- Testing: 1 hour
- Documentation: 30 minutes
- **Total: ~4 hours**

## References
- [Firebase Admin SDK Documentation](https://firebase.google.com/docs/admin/setup)
- [Cloud Functions for Firebase](https://firebase.google.com/docs/functions)
- [Callable Functions](https://firebase.google.com/docs/functions/callable)
- [Firebase Admin Auth API](https://firebase.google.com/docs/auth/admin/manage-users)
