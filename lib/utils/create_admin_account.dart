import '../services/admin_auth_service.dart';

/// Helper script to create the first admin account
/// This should only be run once during initial setup
/// 
/// Usage:
/// 1. Import this in your main.dart temporarily
/// 2. Call createFirstAdmin() from main()
/// 3. Remove the call after admin is created
Future<void> createFirstAdmin() async {
  final adminAuthService = AdminAuthService();
  
  try {
    print('Creating first admin account...');
    
    await adminAuthService.signUpAdmin(
      username: 'admin',
      fullName: 'Super Admin',
      email: 'admin@odctracker.app',
      phoneNumber: '+91 9999999999',
      password: 'admin123456', // Change this immediately after first login!
      permissions: ['full_access'],
    );
    
    print('✅ Admin account created successfully!');
    print('Username: admin');
    print('Password: admin123456');
    print('⚠️  IMPORTANT: Change the password immediately after first login!');
    print('');
    print('Admin login URL: /admin-login');
    
  } catch (e) {
    print('❌ Error creating admin account: $e');
  }
}

/// Create additional admin accounts
Future<void> createAdminAccount({
  required String username,
  required String fullName,
  required String email,
  required String password,
  String? phoneNumber,
  List<String> permissions = const ['full_access'],
}) async {
  final adminAuthService = AdminAuthService();
  
  try {
    print('Creating admin account for $fullName...');
    
    await adminAuthService.signUpAdmin(
      username: username,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      permissions: permissions,
    );
    
    print('✅ Admin account created!');
    print('Username: $username');
    print('Email: $email');
    
  } catch (e) {
    print('❌ Error creating admin account: $e');
  }
}
