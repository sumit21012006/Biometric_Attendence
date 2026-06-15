import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:biometric/models/user_model.dart';
import 'package:biometric/models/attendance_record.dart';
import 'package:biometric/models/office_config.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Retrieve user details by UID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Create a new user record
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  // Update employee device ID
  Future<void> updateDeviceId(String uid, String? deviceId) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'deviceId': deviceId,
      });
    } catch (e) {
      print('Error updating device ID: $e');
      rethrow;
    }
  }

  // Add attendance log
  Future<void> logAttendance(AttendanceRecord record) async {
    try {
      await _firestore.collection('attendance').add(record.toMap());
    } catch (e) {
      print('Error logging attendance: $e');
      rethrow;
    }
  }

  // Retrieve the latest attendance record for an employee
  Future<AttendanceRecord?> getLastAttendanceRecord(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('attendance')
          .where('uid', isEqualTo: uid)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(snapshot.docs);
        docs.sort((a, b) {
          final aTime = a.data()['timestamp'] as Timestamp?;
          final bTime = b.data()['timestamp'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime); // Descending order (latest first)
        });
        return AttendanceRecord.fromMap(docs.first.data(), docs.first.id);
      }
      return null;
    } catch (e) {
      print('Error getting last attendance record: $e');
      return null;
    }
  }

  // Get stream of current user's attendance records
  Stream<List<AttendanceRecord>> getEmployeeAttendanceStream(String uid) {
    return _firestore
        .collection('attendance')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final records = snapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
          .toList();
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort descending in-memory
      return records;
    });
  }

  // Stream of all approved employees (Admin view)
  Stream<List<UserModel>> getEmployeesStream() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'employee')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .where((user) => user.isApproved)
          .toList();
    });
  }

  // Stream of pending employees (Admin approvals view)
  Stream<List<UserModel>> getPendingEmployeesStream() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'employee')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .where((user) => !user.isApproved)
          .toList();
    });
  }

  // Approve employee registration
  Future<void> approveUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isApproved': true,
      });
    } catch (e) {
      print('DatabaseService: Error approving user: $e');
      rethrow;
    }
  }

  // Reject and delete employee registration
  Future<void> rejectUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      print('DatabaseService: Error rejecting user: $e');
      rethrow;
    }
  }

  // Check if a device ID is already bound to any employee in the system (excluding a specific UID)
  Future<bool> isDeviceIdAlreadyBound(String deviceId, {String? excludeUid}) async {
    // Skip validation for default testing fallback device IDs
    if (deviceId == 'web-emulator' || deviceId == 'desktop-emulator' || deviceId == 'unknown-device-id') {
      return false;
    }
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('deviceId', isEqualTo: deviceId)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        if (excludeUid != null) {
          // Check if any OTHER user has this device ID
          return snapshot.docs.any((doc) => doc.id != excludeUid);
        }
        return true;
      }
      return false;
    } catch (e) {
      print('DatabaseService: Error checking device ID binding: $e');
      return false;
    }
  }

  // Check if an Employee ID is already registered in the system (excluding a specific UID if needed)
  Future<bool> isEmployeeIdAlreadyExists(String employeeId, {String? excludeUid}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('employeeId', isEqualTo: employeeId.trim().toUpperCase())
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        if (excludeUid != null) {
          return snapshot.docs.any((doc) => doc.id != excludeUid);
        }
        return true;
      }
      return false;
    } catch (e) {
      print('DatabaseService: Error checking employee ID: $e');
      return false;
    }
  }

  // Stream of all attendance logs (Admin view)
  Stream<List<AttendanceRecord>> getAllAttendanceStream() {
    return _firestore
        .collection('attendance')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get office configuration
  Future<OfficeConfig?> getOfficeConfig() async {
    try {
      final doc = await _firestore.collection('config').doc('office').get();
      if (doc.exists && doc.data() != null) {
        return OfficeConfig.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting office config: $e');
      return null;
    }
  }

  // Save/Update office configuration
  Future<void> saveOfficeConfig(OfficeConfig config) async {
    try {
      await _firestore
          .collection('config')
          .doc('office')
          .set(config.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error saving office config: $e');
      rethrow;
    }
  }
}
