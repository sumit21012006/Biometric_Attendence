import 'package:biometric/config/constants.dart';

class OfficeConfig {
  final double latitude;
  final double longitude;
  final double radius; // in meters
  final String googleSheetsUrl;

  OfficeConfig({
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.googleSheetsUrl,
  });

  factory OfficeConfig.fromMap(Map<String, dynamic> map) {
    return OfficeConfig(
      latitude: (map['latitude'] ?? AppConstants.defaultOfficeLatitude) as double,
      longitude: (map['longitude'] ?? AppConstants.defaultOfficeLongitude) as double,
      radius: (map['radius'] ?? AppConstants.defaultOfficeRadius) as double,
      googleSheetsUrl: map['googleSheetsUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'googleSheetsUrl': googleSheetsUrl,
    };
  }

  OfficeConfig copyWith({
    double? latitude,
    double? longitude,
    double? radius,
    String? googleSheetsUrl,
  }) {
    return OfficeConfig(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      googleSheetsUrl: googleSheetsUrl ?? this.googleSheetsUrl,
    );
  }
}
