import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String designation;
  final String employeeId;
  final String? deviceId; // Uniquely binds employee to this device
  final String role;      // 'employee' or 'admin'
  final DateTime createdAt;
  final String? sevarthId;
  final String? aadhaarNumber;
  final DateTime? joiningDate;
  final bool isApproved;
  final String? schoolName;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.designation,
    required this.employeeId,
    this.deviceId,
    required this.role,
    required this.createdAt,
    this.sevarthId,
    this.aadhaarNumber,
    this.joiningDate,
    this.isApproved = true,
    this.schoolName,
  });

  // Factory constructor to create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      designation: map['designation'] ?? '',
      employeeId: map['employeeId'] ?? '',
      deviceId: map['deviceId'],
      role: map['role'] ?? 'employee',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      sevarthId: map['sevarthId'],
      aadhaarNumber: map['aadhaarNumber'],
      joiningDate: map['joiningDate'] != null
          ? (map['joiningDate'] as Timestamp).toDate()
          : null,
      isApproved: map['isApproved'] ?? true,
      schoolName: map['schoolName'],
    );
  }

  // Convert UserModel to a Map to save to Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'designation': designation,
      'employeeId': employeeId,
      'deviceId': deviceId,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'sevarthId': sevarthId,
      'aadhaarNumber': aadhaarNumber,
      'joiningDate': joiningDate != null ? Timestamp.fromDate(joiningDate!) : null,
      'isApproved': isApproved,
      'schoolName': schoolName,
    };
  }

  // Create a copy of the model with modified fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? designation,
    String? employeeId,
    String? deviceId,
    String? role,
    DateTime? createdAt,
    String? sevarthId,
    String? aadhaarNumber,
    DateTime? joiningDate,
    bool? isApproved,
    String? schoolName,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      designation: designation ?? this.designation,
      employeeId: employeeId ?? this.employeeId,
      deviceId: deviceId, // Direct assignment allows setting to null
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      sevarthId: sevarthId ?? this.sevarthId,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      joiningDate: joiningDate ?? this.joiningDate,
      isApproved: isApproved ?? this.isApproved,
      schoolName: schoolName ?? this.schoolName,
    );
  }
}
