# Admin Panel User Guide

## Table of Contents
1. [Accessing the Admin Panel](#accessing-the-admin-panel)
2. [Dashboard](#dashboard)
3. [User Management](#user-management)
4. [Schedule Management](#schedule-management)
5. [Settings](#settings)
6. [Best Practices](#best-practices)

---

## Accessing the Admin Panel

### Requirements
- Valid admin account with `role: "admin"` in Firestore
- Successfully logged into the app

### Default Admin Credentials (Development)
- **Phone:** `0000011111`
- **Password:** `12345678`
- ⚠️ **Change in production!**

### Login Steps
1. Open ODC Tracker AI app
2. Enter phone number: `0000011111`
3. Enter password: `12345678`
4. Tap "Login"
5. Look for **Admin** tab (6th tab) in bottom navigation
6. Tab color will be orange (not blue)

---

## Dashboard

### Overview
The dashboard provides real-time statistics and quick access to common admin tasks.

### Statistics Cards

#### 1. Total Users
- Shows total registered users
- Includes both active and disabled accounts
- Excludes admin accounts from regular user count

#### 2. Total Schedules
- Number of work schedules created
- Includes all schedules (enabled and disabled)

#### 3. Check-ins Today
- Users who checked in today
- Real-time updates
- Excludes admin check-ins

#### 4. Currently Active
- Users currently working (checked in, not checked out)
- Real-time count
- Updates automatically

### Quick Actions

**Manage Users Button**
- Opens user management screen
- Quick access to user list

**Manage Schedules Button**
- Opens schedule management
- Create or edit work schedules

### Refreshing Data
Pull down on the dashboard to refresh all statistics.

---

## User Management

### Accessing User Management
1. Tap **Admin** tab
2. Tap **Users** in bottom navigation
3. Or tap "Manage Users" on dashboard

### User List

#### Search
- Search by name or email
- Real-time filtering
- Case-insensitive

#### Filters
- **All:** Show all users
- **Active:** Only enabled users
- **Disabled:** Only disabled accounts
- **Admins:** Only admin users

#### User Cards
Each user card shows:
- Profile avatar (first letter of name)
- Full name
- Email or phone number
- Admin badge (if applicable)
- Disabled badge (if applicable)

### User Details

#### Viewing Details
Tap any user card to open their profile.

#### Profile Information
- **Avatar:** Shows first letter of name
- **Full Name**
- **Email Address**
- **Status Badges:** Admin, Disabled

#### Contact Information
**Editable Fields:**
- **Phone Number** - Tap to edit
- **Email Address** - Tap to edit

To edit:
1. Tap the field
2. Enter new value in popup dialog
3. Tap "Save"
4. Field updates in Firestore

#### Account Information
**Read-Only Fields:**
- **Joined Date** - User registration date
- **Last Updated** - Most recent profile update

#### Recent Activity
Shows last 5 attendance records:
- Date
- Check-in time
- Check-out time
- Total hours worked

#### Admin Actions

**Grant/Revoke Admin Access**
1. Tap "Grant Admin Access" or "Revoke Admin Access"
2. Confirm in dialog
3. User's role updates in Firestore
4. User must log out/in to see changes

**Enable/Disable User**
1. Tap "Enable User" or "Disable User"
2. Confirm in dialog
3. Disabled users cannot log in
4. Their data is preserved

---

## Schedule Management

### Accessing Schedules
1. Tap **Admin** tab
2. Tap **Settings** in bottom navigation
3. Tap "Manage Schedules"
4. Or go directly from dashboard

### Schedule List

#### Viewing Schedules
- All work schedules displayed as cards
- Shows name, times, and break duration
- Sorted by creation date

#### Schedule Card Information
- **Name:** Schedule identifier
- **Time Range:** Start - End time (12-hour format)
- **Break Duration:** Allowed break minutes
- **Required ODC:** Required work minutes

#### Actions
- **Tap schedule:** Opens edit form
- **Trash icon:** Deletes schedule (with confirmation)

### Creating a Schedule

#### Steps
1. Tap **+** button in top-right
2. Fill out the form:

**Schedule Name**
- Required field
- Examples: "Day Shift", "Night Shift", "Standard Hours"
- Must be unique and descriptive

**Start Time**
- Tap to open time picker
- Select hour and minute
- Format: 12-hour with AM/PM
- Example: 1:00 PM

**End Time**
- Tap to open time picker
- Can be next day (e.g., 2:00 AM)
- Must be after start time (considering day rollover)
- Example: 10:00 PM

**Break Duration**
- Choose from: 30, 45, 60, or 90 minutes
- Tap to select
- Highlights in orange when selected

**Required ODC Time**
- Choose from: 7, 7.5, 8, or 8.5 hours
- Tap to select
- Typical: 8 hours (480 minutes)

3. Tap "Create Schedule"
4. Schedule saves to Firestore
5. Returns to schedule list

### Editing a Schedule

#### Steps
1. Tap schedule card in list
2. Form opens with current values
3. Edit any field
4. Tap "Update Schedule"
5. Changes save to Firestore

### Deleting a Schedule

#### Steps
1. Tap trash icon on schedule card
2. Confirm deletion in dialog
3. Schedule removed from Firestore
4. Users assigned to this schedule will need a new one

**⚠️ Warning:** Deleting a schedule may affect users currently using it.

---

## Settings

### Accessing Settings
Tap **Settings** in admin bottom navigation.

### Work Schedules
- Link to schedule management
- Same as above section

### Organization Settings (Placeholder)
Future features:
- Company name
- Default shift hours
- Daily goal settings
- Break policies

### Notifications (Placeholder)
Future features:
- Daily report toggles
- Alert preferences
- Email notifications
- Push notification settings

---

## Best Practices

### User Management

**1. Regular Audits**
- Review user list monthly
- Disable inactive accounts
- Remove test accounts

**2. Admin Access**
- Grant admin carefully
- Document who has admin access
- Revoke when no longer needed
- Use principle of least privilege

**3. User Privacy**
- View user data only when necessary
- Don't share user information
- Follow data protection policies

### Schedule Management

**1. Naming Convention**
- Use clear, descriptive names
- Include shift type: "Day Shift A", "Night Shift B"
- Avoid generic names like "Schedule 1"

**2. Schedule Planning**
- Create schedules before assigning to users
- Test schedules before wide deployment
- Consider timezone differences
- Plan for holidays and special days

**3. Schedule Transitions**
- Communicate changes to affected users
- Update schedules at logical times (end of month)
- Keep old schedules for historical data
- Don't delete schedules with active users

### Data Integrity

**1. Backups**
- Firebase handles backups
- Export important data regularly
- Keep audit logs of changes

**2. Testing**
- Test changes on test accounts first
- Verify schedule times work correctly
- Check that validations work

**3. Monitoring**
- Watch for errors in dashboard
- Monitor user complaints
- Check analytics regularly

### Security

**1. Account Security**
- Change default admin password
- Use strong passwords
- Don't share admin credentials
- Log out when done

**2. Access Control**
- Review who has admin access quarterly
- Revoke access for ex-employees immediately
- Use separate admin accounts (no personal use)

**3. Audit Trail**
- Monitor who makes changes
- Document important decisions
- Keep records of admin actions

---

## Troubleshooting

### Common Issues

**Problem:** Admin tab not showing
**Solution:**
- Check user role is "admin" in Firestore
- Log out and back in
- Verify user document exists

**Problem:** Can't edit user
**Solution:**
- Check internet connection
- Verify Firebase permissions
- Try refreshing the page

**Problem:** Schedule not saving
**Solution:**
- Check all required fields filled
- Verify times are valid
- Check Firebase connection
- Review console for errors

**Problem:** Users not seeing schedule changes
**Solution:**
- Users must log out and back in
- Check schedule is enabled
- Verify effectiveFrom/Until dates

### Getting Help

1. Check error messages in app
2. Review Firebase Console logs
3. Check Firestore security rules
4. Contact system administrator
5. Review documentation

---

## Keyboard Shortcuts

Currently no keyboard shortcuts, but coming soon:
- `Ctrl/Cmd + K` - Search users
- `Ctrl/Cmd + N` - New schedule
- `Ctrl/Cmd + R` - Refresh dashboard

---

## Updates and Changes

### Version 2.0.0 (January 2025)
- ✅ Initial admin panel release
- ✅ User management
- ✅ Schedule management
- ✅ Dashboard statistics
- ✅ Real-time updates

### Coming Soon
- 📅 Advanced analytics
- 📅 Bulk user operations
- 📅 Schedule templates
- 📅 Export reports
- 📅 Email notifications
- 📅 Audit logs

---

**Need Help?**
Contact your system administrator or refer to the main documentation.

**Last Updated:** January 2025  
**Version:** 2.0.0
