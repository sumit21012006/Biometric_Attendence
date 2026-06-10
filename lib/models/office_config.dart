import 'package:biometric/config/constants.dart';

class OfficeConfig {
  final double latitude;
  final double longitude;
  final double radius; // in meters
  final String googleSheetsUrl;
  final List<String> adminEmails;

  OfficeConfig({
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.googleSheetsUrl,
    required this.adminEmails,
  });

  factory OfficeConfig.fromMap(Map<String, dynamic> map) {
    return OfficeConfig(
      latitude: (map['latitude'] as num? ?? AppConstants.defaultOfficeLatitude).toDouble(),
      longitude: (map['longitude'] as num? ?? AppConstants.defaultOfficeLongitude).toDouble(),
      radius: (map['radius'] as num? ?? AppConstants.defaultOfficeRadius).toDouble(),
      googleSheetsUrl: map['googleSheetsUrl'] ?? '',
      adminEmails: List<String>.from(map['adminEmails'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'googleSheetsUrl': googleSheetsUrl,
      'adminEmails': adminEmails,
    };
  }

  OfficeConfig copyWith({
    double? latitude,
    double? longitude,
    double? radius,
    String? googleSheetsUrl,
    List<String>? adminEmails,
  }) {
    return OfficeConfig(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      googleSheetsUrl: googleSheetsUrl ?? this.googleSheetsUrl,
      adminEmails: adminEmails ?? this.adminEmails,
    );
  }
}
