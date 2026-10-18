# Admin User Deletion & Audit System Guide

## Overview
This guide covers the comprehensive admin user deletion system with full audit logging capabilities implemented in ODC Tracker AI.

## Features

### 1. Complete User Deletion
- **Firestore Deletion**: Removes user document and all subcollections
- **Firebase Auth Deletion**: Removes user from Firebase Authentication (requires Cloud Function)
- **Audit Trail**: Creates deletion marker in `deleted_users` collection
- **Two-Step Confirmation**: Extra safety with typed confirmation

### 2. Subcollections Deleted
When a user is deleted, ALL of these subcollections are removed:
- `attendance` - All attendance records
- `tasks` - All tasks and to-dos
- `notes` - All user notes
- `workSchedules` - Work schedule assignments
- `reminder_history` - Reminder history
- `sessions` - Session data
- `notifications` - User notifications

### 3. Audit Logging
Every admin action is logged with:
- Admin UID (who performed the action)
- Action type (delete_user, update_user, etc.)
- Target user ID
- Timestamp
- Platform info
- Metadata (additional context)

## User Deletion Flow

### Step 1: Navigate to User Detail
1. Admin logs in with credentials (phone: `0000011111`, password: `12345678`)
2. Go to Admin Panel → Users
3. Tap on a user to view details
4. Scroll to "Danger Zone" section

### Step 2: First Confirmation
Click "Delete User" button. A dialog appears showing:
- User's full name
- List of what will be deleted
- Warning that action cannot be undone

Options:
- **Cancel**: Abort deletion
- **Continue**: Proceed to second confirmation

### Step 3: Second Confirmation (Type DELETE)
For extra safety, you must type `DELETE` (case-insensitive) to confirm.

This prevents accidental deletions and ensures the admin is certain.

### Step 4: Deletion Process
The system performs these actions:
1. **Delete subcollections** (batch operations, 100 docs at a time):
   - attendance records
   - tasks
   - notes
   - workSchedules
   - reminder_history
   - sessions
   - notifications

2. **Create deletion marker** in `deleted_users` collection:
   ```json
   {
     "uid": "user123",
     "deletedAt": "2026-10-17T10:30:00Z",
     "deletedBy": "admin_uid",
     "adminEmail": "admin@example.com",
     "userName": "John Doe",
     "userEmail": "john@example.com",
     "userPhone": "1234567890"
   }
   ```

3. **Delete user document** from `users` collection

4. **Attempt Firebase Auth deletion** (requires Cloud Function for full support)

5. **Log audit event** to `admin_audit_logs` collection

6. **Show success/failure message**

## Audit Logs Screen

### Accessing Audit Logs
Admin Panel → Audit Logs (history icon in bottom navigation)

### Features
- **Real-time streaming**: Logs update automatically
- **Filtering**: Filter by action type (All, Delete User, Update User, etc.)
- **Color coding**: 
  - 🔴 Red: Delete actions
  - 🔵 Blue: Update actions
  - 🟢 Green: Create actions
  - ⚪ Gray: Other actions
- **User details**: Shows admin who performed action and target user
- **Timestamps**: Relative time (e.g., "2 minutes ago")

### Log Information Displayed
- Action type (e.g., "Delete User", "Update User Role")
- Admin name and email
- Target user name
- Timestamp
- Metadata (if available)

## Security

### Firestore Security Rules
The system includes comprehensive security rules in `firestore.rules`:

```javascript
// Admin audit logs - only admins can read, system writes
match /admin_audit_logs/{logId} {
  allow read: if isAdmin();
  allow create: if isAdmin();
  allow update, delete: if false; // Immutable
}

// Deleted users collection - only admins can read
match /deleted_users/{userId} {
  allow read: if isAdmin();
  allow create: if isAdmin();
  allow update, delete: if false; // Immutable
}
```

### Role-Based Access Control
- Only users with `role: 'admin'` can access admin features
- Normal users cannot view or access admin panel
- All admin actions are logged and traceable

### Audit Log Immutability
- Audit logs cannot be modified once created
- Deletion markers cannot be modified once created
- Ensures compliance and forensic integrity

## Technical Implementation

### AdminServiceEnhanced
Located at: `lib/services/admin_service_enhanced.dart`

Key methods:
- `deleteUser(String uid)` - Main deletion orchestrator
- `_deleteUserSubcollections(String uid)` - Batch deletes subcollections
- `_logAuditEvent()` - Creates audit log entries
- `getAuditLogs()` - Streams audit logs with filtering

### User Detail Screen
Located at: `lib/screens/admin/user_detail_screen.dart`

Key methods:
- `_deleteUser()` - UI handler with double confirmation
- Shows danger zone section
- Handles loading states and error messages

### Audit Logs Screen
Located at: `lib/screens/admin/audit_logs_screen.dart`

Features:
- Real-time Firestore streaming
- Filter dropdown for action types
- Color-coded action indicators
- Responsive iOS-style UI

## Database Collections

### admin_audit_logs
```json
{
  "id": "auto_generated",
  "adminUid": "admin_user_id",
  "adminEmail": "admin@example.com",
  "adminName": "Admin Name",
  "action": "delete_user",
  "targetUserId": "deleted_user_id",
  "targetUserName": "User Name",
  "timestamp": "2026-10-17T10:30:00Z",
  "platform": "android",
  "metadata": {
    "reason": "Optional reason",
    "notes": "Additional context"
  }
}
```

### deleted_users
```json
{
  "uid": "deleted_user_id",
  "deletedAt": "2026-10-17T10:30:00Z",
  "deletedBy": "admin_uid",
  "adminEmail": "admin@example.com",
  "userName": "John Doe",
  "userEmail": "john@example.com",
  "userPhone": "1234567890"
}
```

## Known Limitations

### Firebase Auth Deletion
**Current State**: Client-side Firebase Auth deletion only works for self-deletion (current user deleting their own account).

**Why**: Firebase Security Rules prevent one user from deleting another user's authentication account, even admins.

**Solution Required**: Implement Firebase Cloud Function with Admin SDK

#### Cloud Function Example
```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.deleteUser = functions.https.onCall(async (data, context) => {
  // Verify caller is admin
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can delete users'
    );
  }

  const uid = data.uid;

  try {
    await admin.auth().deleteUser(uid);
    return { success: true, message: 'User deleted from Auth' };
  } catch (error) {
    throw new functions.https.HttpsError(
      'internal',
      `Failed to delete user: ${error.message}`
    );
  }
});
```

**Current Behavior**: 
- Firestore deletion works perfectly ✅
- Auth deletion is attempted but may fail
- Success message notes if Auth deletion requires backend
- User is fully removed from app functionality (Firestore data gone)

## Best Practices

### Before Deleting a User
1. **Verify the user**: Double-check you have the right user
2. **Check active sessions**: See if user is currently logged in
3. **Review recent activity**: Check attendance and task history
4. **Export data if needed**: Take screenshots or exports before deletion

### After Deletion
1. **Verify in audit logs**: Confirm action was logged
2. **Check deletion marker**: Verify entry in `deleted_users`
3. **Test app**: Ensure deleted user cannot log in
4. **Monitor for issues**: Watch for any references to deleted user

### Compliance & Legal
- Audit logs provide trail for compliance (GDPR, etc.)
- Deletion markers maintain record of action
- Timestamps are in ISO 8601 format (UTC)
- Admin identity is always captured

## Troubleshooting

### Deletion Fails
**Symptom**: Error message "Failed to delete user"

**Possible Causes**:
1. Network connectivity issue
2. Insufficient permissions
3. User doesn't exist
4. Firestore rules blocking deletion

**Solutions**:
- Check internet connection
- Verify admin role in Firestore
- Confirm user UID is correct
- Review Firestore rules in Firebase Console

### Auth Deletion Fails
**Symptom**: "User deleted from Firestore but not from Auth"

**Cause**: Cloud Function not implemented

**Solution**: 
- User is effectively deleted (can't access app data)
- Implement Cloud Function for complete deletion
- See "Cloud Function Example" above

### Audit Logs Not Appearing
**Symptom**: Deletion successful but no audit log

**Possible Causes**:
1. Firestore rules blocking write
2. Admin user document missing
3. Network issue during log creation

**Solutions**:
- Check Firestore rules for `admin_audit_logs`
- Verify admin user document exists
- Check Firebase Console for error logs

## Related Documentation
- [Firebase Admin Setup](./FIREBASE_ADMIN_SETUP.md) - Admin user provisioning
- [Admin Panel Guide](./ADMIN_PANEL_GUIDE.md) - Complete admin features
- [Firestore Rules](../firestore.rules) - Security rules reference

## Summary

The admin deletion system provides:
- ✅ Complete Firestore deletion (all user data)
- ✅ Comprehensive audit logging
- ✅ Two-step confirmation (extra safety)
- ✅ Immutable audit trail (compliance)
- ✅ Deletion markers (historical record)
- ⚠️ Auth deletion (requires Cloud Function for production)

The system is production-ready for Firestore operations. For complete Firebase Auth deletion, implement the Cloud Function as described above.
