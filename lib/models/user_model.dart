import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String mobileNumber;
  final String? email;
  final String? employeeId;
  final String? profilePhoto;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLogin;
  final String shiftStart;
  final String shiftEnd;
  final int dailyGoal; // in minutes
  final int breakLimit; // in minutes
  final String theme; // 'light', 'dark', 'system'
  final bool notificationEnabled;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.mobileNumber,
    this.email,
    this.employeeId,
    this.profilePhoto,
    required this.createdAt,
    required this.updatedAt,
    this.lastLogin,
    this.shiftStart = '13:00', // 1:00 PM
    this.shiftEnd = '22:00', // 10:00 PM
    this.dailyGoal = 480, // 8 hours
    this.breakLimit = 60, // 1 hour
    this.theme = 'system',
    this.notificationEnabled = true,
  });

  // From Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      mobileNumber: data['mobileNumber'] ?? '',
      email: data['email'],
      employeeId: data['employeeId'],
      profilePhoto: data['profilePhoto'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      lastLogin: data['lastLogin'] != null
          ? (data['lastLogin'] as Timestamp).toDate()
          : null,
      shiftStart: data['shiftStart'] ?? '13:00',
      shiftEnd: data['shiftEnd'] ?? '22:00',
      dailyGoal: data['dailyGoal'] ?? 480,
      breakLimit: data['breakLimit'] ?? 60,
      theme: data['theme'] ?? 'system',
      notificationEnabled: data['notificationEnabled'] ?? true,
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'fullName': fullName,
      'mobileNumber': mobileNumber,
      'email': email,
      'employeeId': employeeId,
      'profilePhoto': profilePhoto,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'shiftStart': shiftStart,
      'shiftEnd': shiftEnd,
      'dailyGoal': dailyGoal,
      'breakLimit': breakLimit,
      'theme': theme,
      'notificationEnabled': notificationEnabled,
    };
  }

  UserModel copyWith({
    String? fullName,
    String? mobileNumber,
    String? email,
    String? employeeId,
    String? profilePhoto,
    DateTime? updatedAt,
    DateTime? lastLogin,
    String? shiftStart,
    String? shiftEnd,
    int? dailyGoal,
    int? breakLimit,
    String? theme,
    bool? notificationEnabled,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      employeeId: employeeId ?? this.employeeId,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
      shiftStart: shiftStart ?? this.shiftStart,
      shiftEnd: shiftEnd ?? this.shiftEnd,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      breakLimit: breakLimit ?? this.breakLimit,
      theme: theme ?? this.theme,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    );
  }
}
