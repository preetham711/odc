import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/main_layout.dart';
import '../../services/admin_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Dedicated admin login screen
/// Separate from user login for security
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _showSetupButton = false;
  bool _isSettingUp = false;

  final _adminAuthService = AdminAuthService();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showSetupButton = false;
    });

    try {
      await _adminAuthService.signInAdmin(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Navigate to main layout which will show admin dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainLayout(),
        ),
      );
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _errorMessage = errorMsg;
        // Show setup button if account not found
        if (errorMsg.contains('not found') || errorMsg.contains('not registered')) {
          _showSetupButton = true;
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _setupAdminAccount() async {
    setState(() {
      _isSettingUp = true;
      _errorMessage = null;
    });

    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      // Check if admin already exists
      UserCredential userCredential;
      String uid;
      
      try {
        // Try to create new account
        userCredential = await auth.createUserWithEmailAndPassword(
          email: 'admin@admin.odctracker.app',
          password: 'Admin@123456',
        );
        uid = userCredential.user!.uid;
        print('✅ Created new admin auth account: $uid');
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          // Account exists, sign in
          userCredential = await auth.signInWithEmailAndPassword(
            email: 'admin@admin.odctracker.app',
            password: 'Admin@123456',
          );
          uid = userCredential.user!.uid;
          print('✅ Using existing admin auth account: $uid');
        } else {
          throw e;
        }
      }

      // Create/update Firestore document
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
      print('✅ Admin Firestore document created');

      if (!mounted) return;

      // Show success and auto-login
      setState(() {
        _errorMessage = null;
        _showSetupButton = false;
        _isSettingUp = false;
      });

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Text('Admin Account Created!', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Admin account has been set up successfully!',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Username: admin', style: TextStyle(color: Colors.white, fontFamily: 'monospace')),
                    Text('Password: Admin@123456', style: TextStyle(color: Colors.white, fontFamily: 'monospace')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '⚠️ Change password after login!',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to main layout
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainLayout()),
                );
              },
              child: const Text('Continue to Dashboard'),
            ),
          ],
        ),
      );

    } catch (e) {
      print('❌ Error setting up admin: $e');
      setState(() {
        _errorMessage = 'Setup failed: ${e.toString()}';
        _isSettingUp = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Admin Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F6EF7), Color(0xFF3A56D4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'Admin Login',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Access administrative dashboard',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Setup Button (shown when admin not found)
                  if (_showSetupButton)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Admin account not found. Click below to create it automatically.',
                                  style: TextStyle(color: Colors.blue, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _isSettingUp ? null : _setupAdminAccount,
                            icon: _isSettingUp
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.build, size: 20),
                            label: Text(_isSettingUp ? 'Creating Admin Account...' : 'Create Admin Account'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Admin Username',
                      hintText: 'Enter admin username',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[900],
                    ),
                    textInputAction: TextInputAction.next,
                    enabled: !_isLoading,
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter password',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[900],
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    enabled: !_isLoading,
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: 32),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F6EF7),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Login as Admin',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Back to User Login
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text(
                      'Back to User Login',
                      style: TextStyle(
                        color: Color(0xFF4F6EF7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Security Notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.security,
                          color: Colors.grey[600],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This is a secure admin portal. Unauthorized access is logged and monitored.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
