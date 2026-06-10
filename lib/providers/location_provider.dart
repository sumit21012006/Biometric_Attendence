import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:biometric/models/office_config.dart';
import 'package:biometric/services/database_service.dart';
import 'package:biometric/config/constants.dart';

class LocationProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  OfficeConfig? _officeConfig;
  Position? _currentPosition;
  double _distanceFromOffice = -1.0; // -1 indicates not calculated yet
  bool _isWithinRange = false;
  bool _isLoading = false;
  bool _isLoadingConfig = false;
  String _locationError = '';

  OfficeConfig? get officeConfig => _officeConfig;
  Position? get currentPosition => _currentPosition;
  double get distanceFromOffice => _distanceFromOffice;
  bool get isWithinRange => _isWithinRange;
  bool get isLoading => _isLoading;
  bool get isLoadingConfig => _isLoadingConfig;
  String get locationError => _locationError;

  LocationProvider() {
    fetchOfficeConfig();
  }

  // Fetch office configurations from Firestore database
  Future<void> fetchOfficeConfig() async {
    _isLoadingConfig = true;
    notifyListeners();

    try {
      _officeConfig = await _dbService.getOfficeConfig();
      if (_officeConfig == null) {
        // First-time installation backup: write default config into database
        final defaultConfig = OfficeConfig(
          latitude: AppConstants.defaultOfficeLatitude,
          longitude: AppConstants.defaultOfficeLongitude,
          radius: AppConstants.defaultOfficeRadius,
          googleSheetsUrl: '',
          adminEmails: AppConstants.defaultAdminEmails,
        );
        await _dbService.saveOfficeConfig(defaultConfig);
        _officeConfig = defaultConfig;
      }
    } catch (e) {
      print('Location Provider: Error loading office configurations: $e');
    } finally {
      _isLoadingConfig = false;
      notifyListeners();
    }
  }

  // Update office config (Admin tool)
  Future<void> updateOfficeConfig(OfficeConfig config) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dbService.saveOfficeConfig(config);
      _officeConfig = config;
      // Re-trigger location verification if coordinates changed
      if (_currentPosition != null) {
        await verifyGeofence();
      }
    } catch (e) {
      print('Location Provider: Error updating office configurations: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get current device location and calculate geofence status
  Future<bool> verifyGeofence() async {
    _isLoading = true;
    _locationError = '';
    notifyListeners();

    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationError = 'Location services are disabled on your device. Please turn on GPS.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _locationError = 'Location permissions are denied. The app cannot verify your presence.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _locationError = 'Location permissions are permanently denied. Please enable them in system settings.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 3. Retrieve high-accuracy location coordinates
      // 3. Retrieve fresh high-accuracy location coordinates
      // Strictly enforced to prevent attendance fraud (spoofing via stale location cache).
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 25),
      );

      _currentPosition = position;

      // 4. Calculate geodesic distance from office
      if (_officeConfig == null) {
        await fetchOfficeConfig();
      }

      final double officeLat = _officeConfig?.latitude ?? AppConstants.defaultOfficeLatitude;
      final double officeLng = _officeConfig?.longitude ?? AppConstants.defaultOfficeLongitude;
      final double allowedRadius = _officeConfig?.radius ?? AppConstants.defaultOfficeRadius;

      _distanceFromOffice = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        officeLat,
        officeLng,
      );

      _isWithinRange = _distanceFromOffice <= allowedRadius;
      print('Location Provider: Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}, Accuracy: ±${position.accuracy.toStringAsFixed(1)}m, Dist: ${_distanceFromOffice.toStringAsFixed(1)}m, Within Range: $_isWithinRange');
      
      _isLoading = false;
      notifyListeners();
      return _isWithinRange;
    } catch (e) {
      _locationError = 'Error acquiring GPS location lock: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Refresh status
  void resetLocation() {
    _currentPosition = null;
    _distanceFromOffice = -1.0;
    _isWithinRange = false;
    _locationError = '';
    notifyListeners();
  }
}
