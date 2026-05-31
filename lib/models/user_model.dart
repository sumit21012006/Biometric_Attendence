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

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.designation,
    required this.employeeId,
    this.deviceId,
    required this.role,
    required this.createdAt,
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
    );
  }
}
