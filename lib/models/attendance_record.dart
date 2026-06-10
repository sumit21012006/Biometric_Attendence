import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  final String id;
  final String uid;
  final String name;
  final String email;
  final String designation;
  final String employeeId;
  final DateTime timestamp;
  final String type; // 'check_in' or 'check_out'
  final String deviceId;
  final double latitude;
  final double longitude;
  final double distance; // Distance from office in meters
  final bool verified;
  final bool isAutoCheckout;

  AttendanceRecord({
    required this.id,
    required this.uid,
    required this.name,
    required this.email,
    required this.designation,
    required this.employeeId,
    required this.timestamp,
    required this.type,
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.verified,
    this.isAutoCheckout = false,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceRecord(
      id: id,
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      designation: map['designation'] ?? '',
      employeeId: map['employeeId'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      type: map['type'] ?? 'check_in',
      deviceId: map['deviceId'] ?? '',
      latitude: (map['latitude'] as num? ?? 0.0).toDouble(),
      longitude: (map['longitude'] as num? ?? 0.0).toDouble(),
      distance: (map['distance'] as num? ?? 0.0).toDouble(),
      verified: map['verified'] ?? false,
      isAutoCheckout: map['isAutoCheckout'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'designation': designation,
      'employeeId': employeeId,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'deviceId': deviceId,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'verified': verified,
      'isAutoCheckout': isAutoCheckout,
    };
  }
}
