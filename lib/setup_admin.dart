import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Automated admin setup script
/// Run this once to create the admin account
/// 
/// Usage: 
/// 1. Uncomment the call in main.dart
/// 2. Run the app once
/// 3. Comment it back out
Future<void> setupAdminAccount() async {
  print('\n═══════════════════════════════════════════════════════');
  print('🚀 Starting Admin Account Setup...');
  print('═══════════════════════════════════════════════════════\n');

  try {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    // Step 1: Check if admin already exists
    print('📝 Step 1: Checking for existing admin account...');
    try {
      final existingUsers = await auth.fetchSignInMethodsForEmail('admin@admin.odctracker.app');
      if (existingUsers.isNotEmpty) {
        print('⚠️  Admin account already exists in Firebase Auth');
        
        // Get the existing user
        final userCredential = await auth.signInWithEmailAndPassword(
          email: 'admin@admin.odctracker.app',
          password: 'Admin@123456',
        );
        
        final uid = userCredential.user!.uid;
        print('✅ Logged in as existing admin: $uid');
        
        // Check if Firestore document exists
        final adminDoc = await firestore.collection('admins').doc(uid).get();
        if (adminDoc.exists) {
          print('✅ Admin document already exists in Firestore');
          print('\n═══════════════════════════════════════════════════════');
          print('✅ ADMIN ACCOUNT ALREADY SETUP!');
          print('═══════════════════════════════════════════════════════');
          print('Username: admin');
          print('Password: Admin@123456');
          print('UID: $uid');
          print('═══════════════════════════════════════════════════════\n');
          return;
        } else {
          print('⚠️  Firestore document missing, will create it...');
          // Continue to create Firestore document
          await _createFirestoreDocument(firestore, uid);
          print('\n═══════════════════════════════════════════════════════');
          print('✅ ADMIN FIRESTORE DOCUMENT CREATED!');
          print('═══════════════════════════════════════════════════════');
          print('Username: admin');
          print('Password: Admin@123456');
          print('UID: $uid');
          print('═══════════════════════════════════════════════════════\n');
          return;
        }
      }
    } catch (e) {
      print('ℹ️  No existing admin account found, will create new one');
    }

    // Step 2: Create Firebase Auth account
    print('\n📝 Step 2: Creating Firebase Auth account...');
    UserCredential userCredential;
    try {
      userCredential = await auth.createUserWithEmailAndPassword(
        email: 'admin@admin.odctracker.app',
        password: 'Admin@123456',
      );
      print('✅ Firebase Auth account created');
    } catch (e) {
      print('❌ Error creating Firebase Auth account: $e');
      return;
    }

    final uid = userCredential.user!.uid;
    print('✅ Admin UID: $uid');

    // Step 3: Create Firestore document
    print('\n📝 Step 3: Creating Firestore document in admins collection...');
    await _createFirestoreDocument(firestore, uid);

    // Step 4: Verify
    print('\n📝 Step 4: Verifying setup...');
    final doc = await firestore.collection('admins').doc(uid).get();
    if (doc.exists) {
      print('✅ Firestore document verified');
      final data = doc.data()!;
      print('   - Username: ${data['username']}');
      print('   - Full Name: ${data['fullName']}');
      print('   - Email: ${data['email']}');
      print('   - Permissions: ${data['permissions']}');
      print('   - Is Active: ${data['isActive']}');
      print('   - Is Super Admin: ${data['isSuperAdmin']}');
    } else {
      print('❌ Verification failed - document not found');
      return;
    }

    print('\n═══════════════════════════════════════════════════════');
    print('🎉 ADMIN ACCOUNT SETUP COMPLETE!');
    print('═══════════════════════════════════════════════════════');
    print('');
    print('Login Credentials:');
    print('  Username: admin');
    print('  Password: Admin@123456');
    print('  Email: admin@admin.odctracker.app');
    print('  UID: $uid');
    print('');
    print('⚠️  IMPORTANT: Change the password after first login!');
    print('');
    print('Next Steps:');
    print('  1. Go to Admin Login screen');
    print('  2. Login with username: admin');
    print('  3. Password: Admin@123456');
    print('  4. You should see the Admin tab in navigation');
    print('  5. Change your password immediately!');
    print('═══════════════════════════════════════════════════════\n');

  } catch (e, stackTrace) {
    print('\n❌ ERROR during setup: $e');
    print('Stack trace: $stackTrace');
    print('\nPlease check:');
    print('1. Firebase is initialized');
    print('2. Internet connection is active');
    print('3. Firebase project is configured correctly');
    print('4. Firestore rules allow writes');
  }
}

Future<void> _createFirestoreDocument(FirebaseFirestore firestore, String uid) async {
  final now = Timestamp.now();
  
  final adminData = {
    'uid': uid,
    'username': 'admin',
    'fullName': 'Super Admin',
    'email': 'admin@admin.odctracker.app',
    'phoneNumber': '+91 9999999999',
    'permissions': ['full_access'],
    'isActive': true,
    'isSuperAdmin': true,
    'createdAt': now,
    'updatedAt': now,
    'lastLogin': null,
  };

  await firestore.collection('admins').doc(uid).set(adminData);
  print('✅ Firestore document created with ${adminData.length} fields');
}

/// Main function to run the setup (for testing)
void main() async {
  print('Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Firebase initialized\n');
  
  await setupAdminAccount();
  
  print('\n✅ Setup script completed. You can now close this.');
}
