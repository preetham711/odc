# Admin System Setup Guide

## Overview

The ODC Tracker AI now has a **completely separate admin authentication system** with:

- ✅ Separate Firestore collection (`admins`) - not in `users`
- ✅ Separate login screen (`/admin-login`)
- ✅ Full access permissions system
- ✅ Admin-specific authentication service
- ✅ Super admin capabilities
- ✅ Secure role-based access control

## Architecture

### Two Admin Types

1. **Regular Users with Admin Role** (Old System - Still Works)
   - Collection: `users`
   - Field: `role: "admin"`
   - Login: Regular user login (`/login`)
   - Use case: Employees who need admin features

2. **Dedicated Admins** (New System - Recommended)
   - Collection: `admins`
   - Separate authentication
   - Login: Admin login (`/admin-login`)
   - Use case: IT admins, super admins

## Firestore Collections

### `admins` Collection

Each admin document contains:

```javascript
{
  uid: string,                    // Firebase Auth UID
  username: string,               // Unique username (e.g., "admin", "john.doe")
  fullName: string,               // Display name
  email: string,                  // Email (username@admin.odctracker.app)
  phoneNumber: string | null,     // Optional phone
  permissions: string[],          // ['full_access'] or specific permissions
  isActive: boolean,              // Can this admin log in?
  isSuperAdmin: boolean,          // Can manage other admins?
  createdAt: timestamp,
  updatedAt: timestamp,
  lastLogin: timestamp | null
}
```

### Available Permissions

```dart
[
  'full_access',        // All permissions
  'view_users',         // View user list
  'edit_users',         // Edit user profiles
  'delete_users',       // Delete users
  'view_attendance',    // View attendance records
  'edit_attendance',    // Edit attendance
  'view_tasks',         // View tasks
  'edit_tasks',         // Edit tasks
  'view_reports',       // View reports
  'manage_admins',      // Create/edit other admins (super admin only)
  'system_settings',    // Change system settings
]
```

## Setup Instructions

### Step 1: Deploy Updated Firestore Rules

```bash
firebase deploy --only firestore:rules
```

This enables the `admins` collection with proper security.

### Step 2: Create First Admin Account

**Option A: Using Firebase Console (Recommended)**

1. Go to **Firebase Console → Authentication**
2. Add a new user:
   - Email: `admin@admin.odctracker.app`
   - Password: `admin123456` (change after first login!)
3. Copy the **UID** of the created user

4. Go to **Firestore Database**
5. Create a new collection named `admins`
6. Add a document with ID = the UID you copied
7. Set these fields:

```
uid: string = [paste the UID]
username: string = admin
fullName: string = Super Admin
email: string = admin@admin.odctracker.app
phoneNumber: string = +91 9999999999
permissions: array = ['full_access']
isActive: boolean = true
isSuperAdmin: boolean = true
createdAt: timestamp = (current time)
updatedAt: timestamp = (current time)
lastLogin: timestamp = null
```

**Option B: Using Code (Quick Setup)**

Add this to your `lib/main.dart` temporarily:

```dart
import 'utils/create_admin_account.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Create first admin - RUN ONCE ONLY!
  // await createFirstAdmin();
  
  runApp(const MyApp());
}
```

Uncomment the line, run the app once, then comment it back out.

### Step 3: Update App Routes

Add the admin login route to your router:

```dart
// In your main.dart or routes file
GoRoute(
  path: '/admin-login',
  name: 'admin-login',
  builder: (context, state) => const AdminLoginScreen(),
),
```

### Step 4: Test Admin Login

1. Navigate to `/admin-login`
2. Login with:
   - **Username:** `admin`
   - **Password:** `admin123456`
3. ✅ You should be redirected to the admin dashboard
4. ⚠️ **Change the password immediately!**

## Admin Login Flow

### User Login vs Admin Login

**User Login (`/login`):**
- For regular employees
- Phone number + password
- Creates/reads from `users` collection
- Can have `role: "admin"` for admin features

**Admin Login (`/admin-login`):**
- For dedicated administrators
- Username + password
- Reads from `admins` collection
- Separate authentication flow
- More secure for admin-only accounts

### Login Process

1. User enters username and password
2. System converts username to admin email format:
   - `admin` → `admin@admin.odctracker.app`
3. Firebase Authentication validates credentials
4. System checks `admins` collection for:
   - Document exists
   - `isActive == true`
5. If valid, user is logged in as admin

## Creating Additional Admins

### Via Code

```dart
import 'package:odc_tracker_ai/utils/create_admin_account.dart';

// Create a new admin
await createAdminAccount(
  username: 'john.doe',
  fullName: 'John Doe',
  email: 'john.doe@company.com',
  password: 'secure_password_here',
  phoneNumber: '+91 9876543210',
  permissions: ['view_users', 'edit_users', 'view_reports'],
);
```

### Via Admin Dashboard (Future Feature)

Once logged in as super admin:
1. Go to Admin Dashboard → Manage Admins
2. Click "Add New Admin"
3. Fill in details
4. Assign permissions
5. Save

## Permission System

### Checking Permissions in Code

```dart
final adminAuthService = AdminAuthService();

// Check if user is an admin
final isAdmin = await adminAuthService.isAdmin();

// Check specific permission
final canDeleteUsers = await adminAuthService.hasPermission('delete_users');

// In the admin model
final admin = await adminAuthService.getAdminProfile(uid);
if (admin.hasPermission('edit_users')) {
  // Show edit button
}
```

### Super Admin Powers

Super admins (`isSuperAdmin: true`) can:
- ✅ Create new admin accounts
- ✅ Edit other admins
- ✅ Deactivate/activate admins
- ✅ Delete admin accounts
- ✅ Change admin permissions
- ✅ View all admin activity

Regular admins **cannot** manage other admin accounts.

## Security Features

### Authentication
- ✅ Separate login flow from regular users
- ✅ Firebase Authentication for credentials
- ✅ Email/password authentication
- ✅ Session management

### Authorization
- ✅ Firestore rules enforce admin-only access
- ✅ Permission-based access control
- ✅ Separate `admins` collection
- ✅ Regular users cannot access admin data
- ✅ Audit logging of admin actions

### Firestore Rules

```javascript
// Only authenticated admins can read admin collection
function isAdminUser() {
  return isSignedIn() && 
         exists(/databases/$(database)/documents/admins/$(request.auth.uid)) &&
         get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.isActive == true;
}

// Either admin type can perform admin operations
function isAnyAdmin() {
  return isAdmin() || isAdminUser();
}
```

## Admin Dashboard Access

### Both Admin Types Have Access

1. **Regular Users with `role: "admin"`**
   - Login via `/login` with phone number
   - Navigate to `/admin` dashboard
   - Full admin features available

2. **Dedicated Admins from `admins` collection**
   - Login via `/admin-login` with username
   - Redirected to `/admin` dashboard
   - Full admin features available

The admin dashboard works for **both** admin types!

## Migration Guide

### If You Have Existing Admin Users

**Option 1: Keep Using Regular Users**
- No changes needed
- Continue using `role: "admin"` in `users` collection
- Login with phone number

**Option 2: Migrate to Dedicated Admins**
1. Create admin accounts in `admins` collection
2. Keep user accounts in `users` for normal access
3. Remove `role: "admin"` from user accounts
4. Admins use `/admin-login`, users use `/login`

**Option 3: Hybrid Approach (Recommended)**
- IT admins → `admins` collection
- Manager-level admins → `users` with `role: "admin"`
- Both have full access

## Testing Checklist

### Admin Login
- [ ] `/admin-login` page loads
- [ ] Login with valid credentials succeeds
- [ ] Login with invalid credentials fails with error
- [ ] Inactive admin cannot log in
- [ ] Regular user credentials don't work on admin login

### Admin Dashboard
- [ ] After login, redirected to `/admin` dashboard
- [ ] All admin features visible
- [ ] Can view users
- [ ] Can edit users
- [ ] Can delete users
- [ ] Can view audit logs

### Permissions
- [ ] Super admin can access "Manage Admins"
- [ ] Regular admin cannot access "Manage Admins"
- [ ] Permission checks work in UI
- [ ] Firestore rules enforce permissions

### Security
- [ ] Regular users cannot access `admins` collection
- [ ] Admin data not visible to regular users
- [ ] Logout works correctly
- [ ] Session persists across page refresh

## Troubleshooting

### "Admin account not found"
- Check `admins` collection in Firestore
- Verify document ID matches Firebase Auth UID
- Check `isActive` field is `true`

### "This account is not an admin account"
- User exists in Firebase Auth but not in `admins` collection
- Create admin document in Firestore

### Cannot access admin features after login
- Check `isActive` field
- Verify permissions array
- Check Firestore rules deployed correctly

### Firestore permission denied
- Deploy updated rules: `firebase deploy --only firestore:rules`
- Check admin document exists
- Verify `isActive == true`

## Best Practices

### Security
1. ✅ Use strong passwords (min 12 characters)
2. ✅ Change default password immediately
3. ✅ Limit super admin accounts (1-2 max)
4. ✅ Regularly review admin access logs
5. ✅ Deactivate unused admin accounts

### Admin Management
1. ✅ Use `full_access` for trusted admins only
2. ✅ Assign specific permissions for limited roles
3. ✅ Keep regular users separate from admin accounts
4. ✅ Document who has admin access
5. ✅ Review permissions quarterly

### Monitoring
1. ✅ Check `admin_audit_logs` regularly
2. ✅ Monitor failed login attempts
3. ✅ Review admin actions weekly
4. ✅ Track permission changes
5. ✅ Alert on suspicious activity

## API Reference

### AdminAuthService

```dart
class AdminAuthService {
  // Check if current user is admin
  Future<bool> isAdmin()
  
  // Get admin profile
  Future<AdminModel?> getAdminProfile(String adminId)
  
  // Sign up new admin
  Future<UserCredential> signUpAdmin({...})
  
  // Sign in admin
  Future<UserCredential> signInAdmin({...})
  
  // Sign out
  Future<void> signOut()
  
  // Update admin profile
  Future<void> updateAdminProfile({...})
  
  // Deactivate admin
  Future<void> deactivateAdmin(String adminId)
  
  // Activate admin
  Future<void> activateAdmin(String adminId)
  
  // Get all admins (super admin only)
  Future<List<AdminModel>> getAllAdmins()
  
  // Check permission
  Future<bool> hasPermission(String permission)
}
```

### AdminModel

```dart
class AdminModel {
  final String uid;
  final String username;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final List<String> permissions;
  final bool isActive;
  final bool isSuperAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLogin;
  
  bool hasPermission(String permission);
}
```

## Summary

✅ **Created:** Separate `admins` collection in Firestore  
✅ **Created:** Admin authentication service  
✅ **Created:** Admin login screen (`/admin-login`)  
✅ **Created:** Admin model with permissions  
✅ **Updated:** Firestore rules for admin access  
✅ **Created:** Setup scripts and documentation  

**Next Steps:**
1. Deploy Firestore rules
2. Create first admin account
3. Test admin login
4. Access admin dashboard

**Default Admin Credentials:**
- Username: `admin`
- Password: `admin123456`
- ⚠️ Change immediately after first login!

---

**Documentation Complete!**  
For questions or issues, check the troubleshooting section above.
