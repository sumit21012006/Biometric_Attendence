import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biometric/config/constants.dart';
import 'package:biometric/providers/auth_provider.dart';
import 'package:biometric/screens/widgets/glass_card.dart';
import 'package:biometric/screens/widgets/premium_button.dart';
import 'package:biometric/screens/widgets/school_banner.dart';
import 'package:biometric/screens/widgets/developer_attribution.dart';
import 'package:biometric/screens/widgets/error_dialog.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({Key? key}) : super(key: key);

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

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
                color: AppConstants.primary.withOpacity(0.12),
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
                color: AppConstants.warning.withOpacity(0.08),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SchoolBanner(vertical: true),
                    const SizedBox(height: 24),

                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Pulsing Hourglass Icon
                          Center(
                            child: ScaleTransition(
                              scale: _pulseAnimation,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppConstants.warning.withOpacity(0.12),
                                  border: Border.all(
                                    color: AppConstants.warning.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.hourglass_empty_rounded,
                                  color: AppConstants.warning,
                                  size: 48,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            'Registration Pending',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppConstants.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          
                          const Text(
                            'Your registration request has been submitted successfully and is awaiting review by a school administrator. You will be able to access the employee portal once approved.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppConstants.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // User info list inside custom container
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'REGISTRATION INFO',
                                  style: TextStyle(
                                    color: AppConstants.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _infoRow(Icons.person_outline_rounded, 'Name', user?.name ?? 'N/A'),
                                const Divider(color: Colors.white12, height: 16),
                                _infoRow(Icons.mail_outline_rounded, 'Email', user?.email ?? 'N/A'),
                                const Divider(color: Colors.white12, height: 16),
                                _infoRow(Icons.school_outlined, 'School Name', user?.schoolName ?? 'N/A'),
                                const Divider(color: Colors.white12, height: 16),
                                _infoRow(Icons.badge_outlined, 'Employee ID', user?.employeeId ?? 'N/A'),
                                const Divider(color: Colors.white12, height: 16),
                                _infoRow(Icons.work_outline_rounded, 'Designation', user?.designation ?? 'N/A'),
                                const Divider(color: Colors.white12, height: 16),
                                _infoRow(Icons.devices_other_rounded, 'Device Fingerprint', user?.deviceId ?? 'N/A', isMonospace: true),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Action button to Check Status
                          PremiumButton(
                            text: 'Check Approval Status',
                            icon: Icons.refresh_rounded,
                            isLoading: auth.isLoading,
                            onPressed: () async {
                              try {
                                await auth.refreshUserStatus();
                                if (auth.currentUser != null && auth.currentUser!.isApproved) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Registration approved! Welcome to Employee Portal.'),
                                        backgroundColor: AppConstants.success,
                                      ),
                                    );
                                  }
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Status refreshed: Still awaiting approval.'),
                                        backgroundColor: AppConstants.warning,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                showErrorDialog(
                                  context,
                                  'Refresh Failed',
                                  e.toString(),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          // Sign out button
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: AppConstants.textSecondary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text(
                              'Log Out / Switch Account',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => auth.signOut(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const DeveloperAttribution(compact: true),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool isMonospace = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppConstants.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AppConstants.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}
