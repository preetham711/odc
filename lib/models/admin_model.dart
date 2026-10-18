import 'package:cloud_firestore/cloud_firestore.dart';

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

  AdminModel({
    required this.uid,
    required this.username,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.permissions = const ['full_access'],
    this.isActive = true,
    this.isSuperAdmin = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastLogin,
  });

  /// Create AdminModel from Firestore document
  factory AdminModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AdminModel(
      uid: doc.id,
      username: data['username'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'],
      permissions: List<String>.from(data['permissions'] ?? ['full_access']),
      isActive: data['isActive'] ?? true,
      isSuperAdmin: data['isSuperAdmin'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'username': username,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'permissions': permissions,
      'isActive': isActive,
      'isSuperAdmin': isSuperAdmin,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }

  /// Create a copy with updated fields
  AdminModel copyWith({
    String? username,
    String? fullName,
    String? email,
    String? phoneNumber,
    List<String>? permissions,
    bool? isActive,
    bool? isSuperAdmin,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
  }) {
    return AdminModel(
      uid: uid,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  /// Check if admin has a specific permission
  bool hasPermission(String permission) {
    if (isSuperAdmin) return true;
    if (permissions.contains('full_access')) return true;
    return permissions.contains(permission);
  }

  /// Available permissions
  static const List<String> availablePermissions = [
    'full_access',
    'view_users',
    'edit_users',
    'delete_users',
    'view_attendance',
    'edit_attendance',
    'view_tasks',
    'edit_tasks',
    'view_reports',
    'manage_admins',
    'system_settings',
  ];

  @override
  String toString() {
    return 'AdminModel(uid: $uid, username: $username, fullName: $fullName, permissions: $permissions, isActive: $isActive, isSuperAdmin: $isSuperAdmin)';
  }
}
