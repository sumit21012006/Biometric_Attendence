import 'package:flutter/foundation.dart';
import 'package:biometric/models/attendance_record.dart';
import 'package:biometric/models/user_model.dart';
import 'package:biometric/providers/auth_provider.dart';
import 'package:biometric/providers/location_provider.dart';
import 'package:biometric/services/database_service.dart';
import 'package:biometric/services/biometrics_service.dart';
import 'package:biometric/services/sheets_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final BiometricsService _biometricsService = BiometricsService();
  final SheetsService _sheetsService = SheetsService();

  bool _isProcessing = false;
  String _statusMessage = '';
  bool _operationSuccess = false;

  bool get isProcessing => _isProcessing;
  String get statusMessage => _statusMessage;
  bool get operationSuccess => _operationSuccess;

  // Primary action method to submit an attendance check
  Future<bool> markAttendance({
    required AuthProvider authProvider,
    required LocationProvider locationProvider,
    required String type, // 'check_in' or 'check_out'
  }) async {
    _isProcessing = true;
    _statusMessage = 'Verifying parameters...';
    _operationSuccess = false;
    notifyListeners();

    try {
      final UserModel? currentUser = authProvider.currentUser;
      if (currentUser == null) {
        _statusMessage = 'Error: User session not found. Please log in.';
        _isProcessing = false;
        notifyListeners();
        return false;
      }

      // 0. Verify check-in/out order sequence logic
      _statusMessage = 'Verifying attendance sequence...';
      notifyListeners();
      
      final AttendanceRecord? lastRecord = await _dbService.getLastAttendanceRecord(currentUser.uid);
      final DateTime now = DateTime.now();
      final bool isLastRecordToday = lastRecord != null &&
          lastRecord.timestamp.year == now.year &&
          lastRecord.timestamp.month == now.month &&
          lastRecord.timestamp.day == now.day;

      if (type == 'check_in') {
        if (isLastRecordToday) {
          _statusMessage = 'Security block: You have already checked in today. Multiple check-ins are not allowed.';
          _isProcessing = false;
          notifyListeners();
          return false;
        }
      } else if (type == 'check_out') {
        if (!isLastRecordToday) {
          _statusMessage = 'Security block: No check-in record found for today. Please check in first.';
          _isProcessing = false;
          notifyListeners();
          return false;
        }
        if (lastRecord.type == 'check_out') {
          _statusMessage = 'Security block: You have already checked out today. Multiple check-outs are not allowed.';
          _isProcessing = false;
          notifyListeners();
          return false;
        }
      }

      // 1. Verify Device Lock Status
      if (authProvider.isDeviceLocked) {
        _statusMessage = 'Error: This device is not registered to your account.';
        _isProcessing = false;
        notifyListeners();
        return false;
      }

      // 2. Geofence presence verification
      _statusMessage = 'Acquiring GPS location lock...';
      notifyListeners();
      
      final bool isWithinOffice = await locationProvider.verifyGeofence();
      if (!isWithinOffice) {
        final double distance = locationProvider.distanceFromOffice;
        if (distance < 0) {
          _statusMessage = 'Location lock failed: ${locationProvider.locationError}';
        } else {
          _statusMessage = 'Security block: You are ${distance.toStringAsFixed(1)}m outside the office boundaries.';
        }
        _isProcessing = false;
        notifyListeners();
        return false;
      }

      // 3. Biometric matching
      _statusMessage = 'Requesting fingerprint verification...';
      notifyListeners();

      final bool biometricPassed = await _biometricsService.authenticate(
        localizedReason: 'Place your finger on the sensor to verify identity for marking attendance.',
      );

      if (!biometricPassed) {
        _statusMessage = 'Biometric matching failed or canceled.';
        _isProcessing = false;
        notifyListeners();
        return false;
      }

      // 4. Create and upload attendance log
      _statusMessage = 'Uploading attendance log...';
      notifyListeners();

      final double distance = locationProvider.distanceFromOffice;
      final double lat = locationProvider.currentPosition?.latitude ?? 0.0;
      final double lng = locationProvider.currentPosition?.longitude ?? 0.0;
      final String devId = authProvider.currentDeviceId ?? 'unknown-dev';

      final record = AttendanceRecord(
        id: '', // Firestore auto-generates
        uid: currentUser.uid,
        name: currentUser.name,
        email: currentUser.email,
        designation: currentUser.designation,
        employeeId: currentUser.employeeId,
        timestamp: DateTime.now(),
        type: type,
        deviceId: devId,
        latitude: lat,
        longitude: lng,
        distance: distance,
        verified: true,
      );

      // Write to Firestore database
      await _dbService.logAttendance(record);

      // 5. Sync to Google Sheets Spreadsheet via Apps Script
      final String sheetsWebhookUrl = locationProvider.officeConfig?.googleSheetsUrl ?? '';
      if (sheetsWebhookUrl.isNotEmpty) {
        _statusMessage = 'Syncing log to Google Sheet...';
        notifyListeners();
        await _sheetsService.sendRecordToSheet(sheetsWebhookUrl, record);
      }

      _statusMessage = 'Attendance marked successfully!';
      _operationSuccess = true;
      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _statusMessage = 'Error occurred: ${e.toString()}';
      _isProcessing = false;
      _operationSuccess = false;
      notifyListeners();
      return false;
    }
  }

  void clearStatus() {
    _statusMessage = '';
    _operationSuccess = false;
    _isProcessing = false;
    notifyListeners();
  }
}
