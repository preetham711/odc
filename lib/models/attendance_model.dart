import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String userId;
  final DateTime date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int odcTime; // in minutes
  final int breakTime; // in minutes
  final List<SessionModel> sessions;
  final bool isActive;
  final int remainingODC;
  final int remainingBreak;
  final double completionPercentage;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.odcTime = 0,
    this.breakTime = 0,
    this.sessions = const [],
    this.isActive = false,
    this.remainingODC = 480,
    this.remainingBreak = 60,
    this.completionPercentage = 0.0,
  });

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      checkIn: data['checkIn'] != null
          ? (data['checkIn'] as Timestamp).toDate()
          : null,
      checkOut: data['checkOut'] != null
          ? (data['checkOut'] as Timestamp).toDate()
          : null,
      odcTime: data['odcTime'] ?? 0,
      breakTime: data['breakTime'] ?? 0,
      sessions: (data['sessions'] as List<dynamic>?)
              ?.map((s) => SessionModel.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      isActive: data['isActive'] ?? false,
      remainingODC: data['remainingODC'] ?? 480,
      remainingBreak: data['remainingBreak'] ?? 60,
      completionPercentage: (data['completionPercentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'checkIn': checkIn != null ? Timestamp.fromDate(checkIn!) : null,
      'checkOut': checkOut != null ? Timestamp.fromDate(checkOut!) : null,
      'odcTime': odcTime,
      'breakTime': breakTime,
      'sessions': sessions.map((s) => s.toMap()).toList(),
      'isActive': isActive,
      'remainingODC': remainingODC,
      'remainingBreak': remainingBreak,
      'completionPercentage': completionPercentage,
    };
  }

  AttendanceModel copyWith({
    DateTime? checkIn,
    DateTime? checkOut,
    int? odcTime,
    int? breakTime,
    List<SessionModel>? sessions,
    bool? isActive,
    int? remainingODC,
    int? remainingBreak,
    double? completionPercentage,
  }) {
    return AttendanceModel(
      id: id,
      userId: userId,
      date: date,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      odcTime: odcTime ?? this.odcTime,
      breakTime: breakTime ?? this.breakTime,
      sessions: sessions ?? this.sessions,
      isActive: isActive ?? this.isActive,
      remainingODC: remainingODC ?? this.remainingODC,
      remainingBreak: remainingBreak ?? this.remainingBreak,
      completionPercentage: completionPercentage ?? this.completionPercentage,
    );
  }
}

class SessionModel {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final String type; // 'odc' or 'break'
  final int duration; // in minutes

  SessionModel({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.type,
    this.duration = 0,
  });

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: map['endTime'] != null
          ? (map['endTime'] as Timestamp).toDate()
          : null,
      type: map['type'] ?? 'odc',
      duration: map['duration'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'type': type,
      'duration': duration,
    };
  }
}
