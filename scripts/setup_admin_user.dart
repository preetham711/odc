import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to create the default admin user
/// Run this once to set up the admin account in Firebase
/// 
/// Usage:
/// 1. Add this to your main.dart temporarily
/// 2. Call setupAdminUser() once
/// 3. Remove after setup is complete

Future<void> setupAdminUser() async {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  print('🔧 Setting up admin user...');

  try {
    // Check if admin user already exists
    final existingUsers = await firestore
        .collection('users')
        .where('mobileNumber', isEqualTo: '0000011111')
        .limit(1)
        .get();

    if (existingUsers.docs.isNotEmpty) {
      print('✅ Admin user already exists!');
      final doc = existingUsers.docs.first;
      print('   UID: ${doc.id}');
      print('   Role: ${doc.data()['role']}');
      
      // Update to ensure role is admin
      await firestore.collection('users').doc(doc.id).update({
        'role': 'admin',
        'isDisabled': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Admin role verified and updated');
      return;
    }

    // Create Firebase Auth user
    // Note: Firebase Phone Auth requires SMS verification in production
    // For development, you can create via Firebase Console or use email auth
    
    print('Creating admin user in Firebase Auth...');
    print('⚠️  IMPORTANT: For phone auth, you need to:');
    print('   1. Go to Firebase Console → Authentication');
    print('   2. Add user manually with phone: +910000011111');
    print('   3. Or use email: admin@odctracker.com / 12345678');
    print('   4. Then run this script again to create Firestore document');
    
    // Alternative: Create with email (easier for testing)
    UserCredential? credential;
    try {
      credential = await auth.createUserWithEmailAndPassword(
        email: 'admin@odctracker.com',
        password: '12345678',
      );
      print('✅ Created auth user with email');
    } catch (e) {
      // If user exists, try to sign in
      try {
        credential = await auth.signInWithEmailAndPassword(
          email: 'admin@odctracker.com',
          password: '12345678',
        );
        print('✅ Found existing auth user');
      } catch (e2) {
        print('❌ Error with auth: $e2');
        return;
      }
    }

    if (credential?.user == null) {
      print('❌ Could not create/find auth user');
      return;
    }

    final uid = credential!.user!.uid;
    print('✅ Auth user ready. UID: $uid');

    // Create Firestore user document
    print('Creating Firestore user document...');
    
    await firestore.collection('users').doc(uid).set({
      'uid': uid,
      'fullName': 'System Admin',
      'mobileNumber': '0000011111',
      'email': 'admin@odctracker.com',
      'employeeId': 'ADMIN001',
      'role': 'admin', // 🔑 This is the key field!
      'isDisabled': false,
      'profilePhoto': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
      'shiftStart': '13:00',
      'shiftEnd': '22:00',
      'dailyGoal': 480,
      'breakLimit': 60,
      'theme': 'system',
      'notificationEnabled': true,
    });

    print('✅ Admin user created successfully!');
    print('');
    print('📋 Login Credentials:');
    print('   Phone: 0000011111');
    print('   Email: admin@odctracker.com');
    print('   Password: 12345678');
    print('');
    print('🎯 Next Steps:');
    print('   1. Restart the app');
    print('   2. Login with the credentials above');
    print('   3. You should see 6 tabs with orange "Admin" tab');
    print('   4. Tap Admin tab to access admin dashboard');
    print('');
    print('⚠️  SECURITY: Change password in production!');

  } catch (e, stack) {
    print('❌ Error setting up admin user: $e');
    print('Stack trace: $stack');
  }
}

/// Verify admin user exists and has correct role
Future<bool> verifyAdminUser(String uid) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists) {
      print('❌ User document does not exist');
      return false;
    }

    final data = doc.data()!;
    final role = data['role'] as String?;
    final isDisabled = data['isDisabled'] as bool? ?? false;

    print('👤 User Info:');
    print('   Name: ${data['fullName']}');
    print('   Phone: ${data['mobileNumber']}');
    print('   Role: $role');
    print('   Disabled: $isDisabled');

    if (role != 'admin') {
      print('❌ User is not an admin (role: $role)');
      return false;
    }

    if (isDisabled) {
      print('❌ User account is disabled');
      return false;
    }

    print('✅ Admin user verified successfully!');
    return true;

  } catch (e) {
    print('❌ Error verifying user: $e');
    return false;
  }
}

/// Grant admin access to an existing user
Future<void> grantAdminAccess(String uid) async {
  try {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'role': 'admin',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('✅ Admin access granted to user: $uid');
  } catch (e) {
    print('❌ Error granting admin access: $e');
  }
}
