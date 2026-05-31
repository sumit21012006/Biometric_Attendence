import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biometric/config/constants.dart';
import 'package:biometric/providers/auth_provider.dart';
import 'package:biometric/screens/widgets/glass_card.dart';
import 'package:biometric/screens/widgets/premium_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _designationController = TextEditingController();
  final _employeeIdController = TextEditingController();

  @override
  void dispose() {
    _designationController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: Stack(
        children: [
          // Ambient lighting
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConstants.primary.withOpacity(0.12),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Icon(
                        Icons.assignment_ind_rounded,
                        size: 70,
                        color: AppConstants.secondary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Complete Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome, ${auth.tempGoogleUser?.displayName ?? "Employee"}! Please submit your details below to bind this device to your employee account.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Form card
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Custom Input field: Employee ID
                            const Text(
                              'Employee ID / Code',
                              style: TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _employeeIdController,
                              style: const TextStyle(color: AppConstants.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'e.g. EMP-2026-042',
                                hintStyle: const TextStyle(color: AppConstants.textSecondary),
                                prefixIcon: const Icon(Icons.badge, color: AppConstants.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppConstants.primary),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.02),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your Employee ID';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Custom Input field: Designation
                            const Text(
                              'Job Designation',
                              style: TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _designationController,
                              style: const TextStyle(color: AppConstants.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'e.g. Marketing Manager',
                                hintStyle: const TextStyle(color: AppConstants.textSecondary),
                                prefixIcon: const Icon(Icons.work, color: AppConstants.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppConstants.primary),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.02),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your designation';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),

                            // Submit Button
                            PremiumButton(
                              text: 'Register Account',
                              icon: Icons.check_circle_outline_rounded,
                              gradient: AppConstants.secondaryGradient,
                              isLoading: auth.isLoading,
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  try {
                                    await auth.signUpEmployee(
                                      designation: _designationController.text.trim(),
                                      employeeId: _employeeIdController.text.trim(),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Registration Error: ${e.toString()}'),
                                        backgroundColor: AppConstants.error,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => auth.signOut(),
                        child: const Text(
                          'Cancel & Sign Out',
                          style: TextStyle(color: AppConstants.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
