import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricsService {
  final LocalAuthentication _auth = LocalAuthentication();

  // Check if biometric hardware exists and is configured on the device
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics && isDeviceSupported;
    } on PlatformException catch (e) {
      print('Biometrics check error: $e');
      return false;
    }
  }

  // Authenticate user using biometric sensors (with standard PIN/pattern fallback)
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: false, // Allows PIN/Pattern fallback if biometrics fail or aren't set
          stickyAuth: true,     // Persist if app goes to background during authentication
          useErrorDialogs: true, // Let OS handle standard error dialogs
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Authentication prompt error: $e');
      return false;
    }
  }
}
