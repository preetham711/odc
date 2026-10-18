import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

/// Quick script to add admin user to Firestore
/// 
/// PREREQUISITES:
/// 1. Admin user must already exist in Firebase Authentication
/// 2. Get the UID from Firebase Console -> Authentication -> Users
/// 3. Replace ADMIN_UID below with that UID
/// 
/// RUN: dart run scripts/add_admin_to_firestore.dart

void main() async {
  print('🚀 Starting Firestore Admin Setup...\n');

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized\n');

    final firestore = FirebaseFirestore.instance;

    // ⚠️ REPLACE THIS WITH YOUR ACTUAL ADMIN UID FROM FIREBASE AUTH
    const adminUid = 'SUkOsfIA55N7KSzyfRy33ckmMZf2';
    
    print('📝 Creating admin user document...');
    print('UID: $adminUid\n');

    final adminData = {
      'uid': adminUid,
      'fullName': 'Admin User',
      'mobileNumber': '0000011111',
      'email': 'admin@odctracker.app',
      'role': 'admin',
      'isDisabled': false,
      'employeeId': 'ADMIN001',
      'shiftStart': '13:00',
      'shiftEnd': '22:00',
      'dailyGoal': 480,
      'breakLimit': 60,
      'theme': 'system',
      'notificationEnabled': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    };

    await firestore
        .collection('users')
        .doc(adminUid)
        .set(adminData);

    print('✅ Admin user created successfully!\n');
    print('📋 Admin Details:');
    print('   Name: Admin User');
    print('   Mobile: 0000011111');
    print('   Email: admin@odctracker.app');
    print('   Role: admin');
    print('   Employee ID: ADMIN001');
    print('   Shift: 13:00 - 22:00\n');
    
    print('🎉 Setup complete!\n');
    print('📱 You can now login with:');
    print('   Mobile: 0000011111');
    print('   Password: 12345678\n');
    
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('\nStack trace:');
    print(stackTrace);
    print('\n💡 Make sure:');
    print('   1. Firebase Authentication user exists');
    print('   2. UID is correct');
    print('   3. Firebase is properly configured');
  }
}
