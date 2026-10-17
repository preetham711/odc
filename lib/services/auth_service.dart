import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  String? get currentUserId => _auth.currentUser?.uid;

  // Derive email from mobile (same formula used everywhere)
  String _emailFromMobile(String mobile) => '$mobile@odctracker.app';

  // ─── Sign Up ────────────────────────────────────────────────────────────────
  // We create the Firebase Auth account FIRST (so request.auth is set),
  // then write the Firestore profile (now authenticated → rules pass).
  // The unauthenticated duplicate-mobile check is removed; if the email
  // already exists Firebase Auth throws 'email-already-in-use'.
  Future<UserCredential> signUp({
    required String fullName,
    required String mobileNumber,
    required String password,
    String? email,
    String? employeeId,
  }) async {
    try {
      final emailToUse = email ?? _emailFromMobile(mobileNumber);

      // 1. Create Firebase Auth account (unauthenticated → authenticated)
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );

      // 2. Now authenticated — write Firestore profile
      final user = UserModel(
        uid: userCredential.user!.uid,
        fullName: fullName,
        mobileNumber: mobileNumber,
        email: email,
        employeeId: employeeId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(user.toFirestore());

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      rethrow;
    }
  }

  // ─── Sign In ────────────────────────────────────────────────────────────────
  // Derive the email directly from the mobile number — no Firestore read
  // needed before authenticating. After sign-in we update lastLogin.
  Future<UserCredential> signIn({
    required String mobileNumber,
    required String password,
  }) async {
    try {
      // Try with the proxy email first
      String emailToTry = _emailFromMobile(mobileNumber);

      UserCredential userCredential;
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: emailToTry,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          // Maybe they registered with a real email — look up after first
          // attempt fails (at this point we still have no auth token so
          // we fall through to the friendlier error below)
          throw Exception('Mobile number not registered');
        }
        throw Exception(_handleAuthException(e));
      }

      // Now authenticated — update lastLogin (best-effort, ignore errors)
      try {
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({'lastLogin': Timestamp.fromDate(DateTime.now())});
      } catch (_) {}

      return userCredential;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  // ─── Sign Out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  // ─── Reset Password ─────────────────────────────────────────────────────────
  // Derive email from mobile directly — no unauthenticated Firestore read.
  Future<void> resetPassword(String mobileNumber) async {
    try {
      final email = _emailFromMobile(mobileNumber);
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      rethrow;
    }
  }

  // ─── Get User Profile ────────────────────────────────────────────────────────
  Future<UserModel> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) throw Exception('User profile not found');
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }

  // ─── Update User Profile ─────────────────────────────────────────────────────
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  bool isLoggedIn() => _auth.currentUser != null;

  // ─── Delete Account ──────────────────────────────────────────────────────────
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).delete();
        await user.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }

  // ─── Internal ────────────────────────────────────────────────────────────────
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak (min 6 characters)';
      case 'email-already-in-use':
        return 'This mobile number is already registered';
      case 'user-not-found':
      case 'invalid-credential':
        return 'Mobile number not registered or wrong password';
      case 'wrong-password':
        return 'Wrong password';
      case 'invalid-email':
        return 'Invalid mobile number format';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'network-request-failed':
        return 'Network error. Check your internet connection';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
