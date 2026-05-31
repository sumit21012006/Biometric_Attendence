import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:biometric/models/user_model.dart';
import 'package:biometric/services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseService _dbService = DatabaseService();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _currentDeviceId;
  bool _isDeviceLocked = false;
  bool _isSignupRequired = false;
  
  // Temporary cache of Google Auth Info during signup redirect
  User? _tempGoogleUser;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get currentDeviceId => _currentDeviceId;
  bool get isDeviceLocked => _isDeviceLocked;
  bool get isSignupRequired => _isSignupRequired;
  User? get tempGoogleUser => _tempGoogleUser;

  AuthProvider() {
    _init();
  }

  // Initialize and check current user status
  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    await _fetchCurrentDeviceId();

    final User? firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      await _loadUserAndVerifyDevice(firebaseUser);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Fetch unique device hardware ID
  Future<void> _fetchCurrentDeviceId() async {
    try {
      if (kIsWeb) {
        _currentDeviceId = "web-emulator";
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _currentDeviceId = androidInfo.id; // Hardware serial/id
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _currentDeviceId = iosInfo.identifierForVendor; // Vendor identifier
      } else {
        _currentDeviceId = "desktop-emulator";
      }
      print('Auth Provider: Loaded device ID: $_currentDeviceId');
    } catch (e) {
      _currentDeviceId = "unknown-device-id";
      print('Auth Provider: Error reading device ID: $e');
    }
  }

  // Signs in using Google Authentication and runs device validations
  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _isDeviceLocked = false;
    _isSignupRequired = false;
    _tempGoogleUser = null;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User aborted the sign-in flow
        _isLoading = false;
        notifyListeners();
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        await _loadUserAndVerifyDevice(firebaseUser);
      }
    } catch (e) {
      print('Google sign-in error: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Internal method to load user database details and enforce device-binding limits
  Future<void> _loadUserAndVerifyDevice(User firebaseUser) async {
    final UserModel? dbUser = await _dbService.getUser(firebaseUser.uid);

    if (dbUser == null) {
      // First-time login: redirect to sign-up details page
      _tempGoogleUser = firebaseUser;
      _isSignupRequired = true;
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Existing user: check role and enforce device bindings
    if (dbUser.role == 'admin') {
      // Admins are unlocked (can access panels from any desktop/tablet)
      _currentUser = dbUser;
      _isDeviceLocked = false;
    } else {
      // Employee: verify device binding status
      if (dbUser.deviceId == null) {
        // Device is unbound (e.g. initial login or admin-reset). Bind it now!
        await _dbService.updateDeviceId(firebaseUser.uid, _currentDeviceId);
        _currentUser = dbUser.copyWith(deviceId: _currentDeviceId);
        _isDeviceLocked = false;
      } else if (dbUser.deviceId == _currentDeviceId) {
        // Device matched. Authenticate!
        _currentUser = dbUser;
        _isDeviceLocked = false;
      } else {
        // Device mismatch! Block access and force sign-out.
        _isDeviceLocked = true;
        _currentUser = null;
        await signOut(silent: true);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Register a new employee user
  Future<void> signUpEmployee({
    required String name,
    required String designation,
    required String employeeId,
  }) async {
    if (_tempGoogleUser == null || _currentDeviceId == null) {
      throw Exception('Missing Google info or Device ID for registration.');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final newUser = UserModel(
        uid: _tempGoogleUser!.uid,
        name: name,
        email: _tempGoogleUser!.email ?? '',
        designation: designation,
        employeeId: employeeId,
        deviceId: _currentDeviceId, // Binds current hardware device ID
        role: 'employee',
        createdAt: DateTime.now(),
      );

      await _dbService.createUser(newUser);
      _currentUser = newUser;
      _isSignupRequired = false;
      _tempGoogleUser = null;
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign out
  Future<void> signOut({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
    _currentUser = null;
    
    if (!silent) {
      _isDeviceLocked = false;
      _isSignupRequired = false;
      _tempGoogleUser = null;
      _isLoading = false;
    }
    notifyListeners();
  }

  // Reset lock (allows user to clear state and try logging in again)
  void clearLock() {
    _isDeviceLocked = false;
    _isSignupRequired = false;
    _tempGoogleUser = null;
    notifyListeners();
  }
}
