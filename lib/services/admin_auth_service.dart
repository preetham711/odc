import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_model.dart';

/// Service for admin-specific authentication
/// Admins are stored in a separate 'admins' collection in Firestore
class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  String? get currentAdminId => _auth.currentUser?.uid;

  // Derive admin email from username
  String _emailFromUsername(String username) => '$username@admin.odctracker.app';

  /// Check if current user is an admin
  Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final adminDoc = await _firestore
          .collection('admins')
          .doc(user.uid)
          .get();
      
      return adminDoc.exists && adminDoc.data()?['isActive'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Get admin profile
  Future<AdminModel?> getAdminProfile(String adminId) async {
    try {
      final doc = await _firestore
          .collection('admins')
          .doc(adminId)
          .get();

      if (!doc.exists) return null;
      return AdminModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch admin profile: $e');
    }
  }

  /// Admin Sign Up (for creating new admin accounts)
  /// This should typically only be called by a super admin or setup script
  Future<UserCredential> signUpAdmin({
    required String username,
    required String fullName,
    required String password,
    required String email,
    String? phoneNumber,
    List<String> permissions = const ['full_access'],
  }) async {
    try {
      final adminEmail = email.isNotEmpty ? email : _emailFromUsername(username);

      // 1. Create Firebase Auth account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: password,
      );

      // 2. Create admin profile in 'admins' collection
      final admin = AdminModel(
        uid: userCredential.user!.uid,
        username: username,
        fullName: fullName,
        email: adminEmail,
        phoneNumber: phoneNumber,
        permissions: permissions,
        isActive: true,
        isSuperAdmin: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _firestore
          .collection('admins')
          .doc(userCredential.user!.uid)
          .set(admin.toFirestore());

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      rethrow;
    }
  }

  /// Admin Sign In
  Future<UserCredential> signInAdmin({
    required String username,
    required String password,
  }) async {
    try {
      // Try with admin email format
      String emailToTry = _emailFromUsername(username);

      UserCredential userCredential;
      
      // First try with username-based email
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: emailToTry,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          // Maybe they used a real email
          // Try the username as-is if it looks like an email
          if (username.contains('@')) {
            userCredential = await _auth.signInWithEmailAndPassword(
              email: username,
              password: password,
            );
          } else {
            throw Exception('Admin account not found');
          }
        } else {
          throw Exception(_handleAuthException(e));
        }
      }

      // Verify this user is actually an admin
      final adminDoc = await _firestore
          .collection('admins')
          .doc(userCredential.user!.uid)
          .get();

      if (!adminDoc.exists) {
        await _auth.signOut();
        throw Exception('This account is not an admin account');
      }

      final adminData = adminDoc.data()!;
      if (adminData['isActive'] != true) {
        await _auth.signOut();
        throw Exception('Admin account is disabled');
      }

      // Update lastLogin
      try {
        await _firestore
            .collection('admins')
            .doc(userCredential.user!.uid)
            .update({
              'lastLogin': Timestamp.fromDate(DateTime.now()),
              'updatedAt': Timestamp.fromDate(DateTime.now()),
            });
      } catch (_) {}

      return userCredential;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Update admin profile
  Future<void> updateAdminProfile({
    required String adminId,
    String? fullName,
    String? phoneNumber,
    List<String>? permissions,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (fullName != null) updates['fullName'] = fullName;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (permissions != null) updates['permissions'] = permissions;

      await _firestore
          .collection('admins')
          .doc(adminId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update admin profile: $e');
    }
  }

  /// Deactivate admin account
  Future<void> deactivateAdmin(String adminId) async {
    await _firestore
        .collection('admins')
        .doc(adminId)
        .update({
          'isActive': false,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
  }

  /// Activate admin account
  Future<void> activateAdmin(String adminId) async {
    await _firestore
        .collection('admins')
        .doc(adminId)
        .update({
          'isActive': true,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
  }

  /// Get all admins (for super admin)
  Future<List<AdminModel>> getAllAdmins() async {
    try {
      final snapshot = await _firestore
          .collection('admins')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AdminModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch admins: $e');
    }
  }

  /// Check if admin has specific permission
  Future<bool> hasPermission(String permission) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final adminDoc = await _firestore
          .collection('admins')
          .doc(user.uid)
          .get();

      if (!adminDoc.exists) return false;

      final adminData = adminDoc.data()!;
      
      // Super admin has all permissions
      if (adminData['isSuperAdmin'] == true) return true;

      // Check if admin has full_access or specific permission
      final permissions = List<String>.from(adminData['permissions'] ?? []);
      return permissions.contains('full_access') || permissions.contains(permission);
    } catch (e) {
      return false;
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password should be at least 6 characters';
      case 'email-already-in-use':
        return 'An admin account with this username already exists';
      case 'user-not-found':
        return 'Admin account not found';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid username format';
      case 'user-disabled':
        return 'This admin account has been disabled';
      case 'invalid-credential':
        return 'Invalid username or password';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
