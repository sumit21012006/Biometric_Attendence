import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biometric/config/constants.dart';
import 'package:biometric/providers/auth_provider.dart';
import 'package:biometric/screens/auth/signup_screen.dart';
import 'package:biometric/screens/widgets/glass_card.dart';
import 'package:biometric/screens/widgets/premium_button.dart';
import 'package:biometric/screens/widgets/school_banner.dart';
import 'package:biometric/screens/widgets/developer_attribution.dart';
import 'package:biometric/screens/widgets/error_dialog.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      body: Stack(
        children: [
          // Background soft glowing light spots
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConstants.primary.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConstants.secondary.withOpacity(0.1),
              ),
            ),
          ),
          // Content Layout
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    // Check if redirect flows are triggered
                    if (auth.isSignupRequired && auth.tempGoogleUser != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const SignupScreen()),
                        );
                      });
                    }

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // School Branding Banner
                        const SchoolBanner(vertical: true),
                        const SizedBox(height: 32),

                        // Login Form Container
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Authorized Access Only',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppConstants.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Mark attendance securely by validating your Google account, device fingerprint, and physical GPS location.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppConstants.textSecondary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              if (auth.isDeviceLocked) ...[
                                // Device Lock Warning Box
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppConstants.error.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppConstants.error.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.warning_amber_rounded, color: AppConstants.error),
                                          SizedBox(width: 8),
                                          Text(
                                            'Device ID Mismatch!',
                                            style: TextStyle(
                                              color: AppConstants.error,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'This account is registered on another device. For security, you can only log in from your primary device.\n\nPlease contact the administrator to reset your registered Device ID if you have changed your phone.',
                                        style: TextStyle(
                                          color: AppConstants.textSecondary,
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextButton(
                                        onPressed: auth.clearLock,
                                        child: const Text('Try Another Account'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ] else ...[
                                // Normal Google Sign-in trigger
                                PremiumButton(
                                  text: 'Sign In with Google',
                                  icon: Icons.login_rounded,
                                  isLoading: auth.isLoading,
                                  onPressed: () async {
                                    try {
                                      await auth.signInWithGoogle();
                                    } catch (e) {
                                      showErrorDialog(
                                        context,
                                        'Authentication Failed',
                                        e.toString(),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        Text(
                          'Current Device: ${auth.currentDeviceId ?? "Fetching..."}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const DeveloperAttribution(compact: true),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
