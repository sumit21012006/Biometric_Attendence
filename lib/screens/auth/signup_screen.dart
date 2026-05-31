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
  final _nameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  String? _selectedDesignation;

  // Curated list of official job designations
  final List<String> _designations = [
    'Head Master',
    'Clerk',
    'Primary Teacher',
    'Secondary Teacher',
    'Non teaching staff',
  ];

  @override
  void initState() {
    super.initState();
    // Proactively seed the name textfield from Google Authentication display metadata
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      _nameController.text = auth.tempGoogleUser?.displayName ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
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
          // Ambient lighting background glow
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
                      // Header Branding
                      const Icon(
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
                        'Welcome! Please submit your details below to bind this device to your employee account.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Form input container card
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Custom Input field: Employee Name
                            const Text(
                              'Full Name',
                              style: TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: AppConstants.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Enter your full name',
                                hintStyle: const TextStyle(color: AppConstants.textSecondary),
                                prefixIcon: const Icon(Icons.person, color: AppConstants.primary),
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
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

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

                            // Custom Dropdown field: Designation
                            const Text(
                              'Job Designation',
                              style: TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedDesignation,
                              dropdownColor: AppConstants.cardBg,
                              style: const TextStyle(color: AppConstants.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Select Designation',
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
                              items: _designations.map((designation) {
                                return DropdownMenuItem<String>(
                                  value: designation,
                                  child: Text(
                                    designation,
                                    style: const TextStyle(color: AppConstants.textPrimary),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDesignation = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select your designation';
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
                                if (_formKey.currentState!.validate() && _selectedDesignation != null) {
                                  try {
                                    await auth.signUpEmployee(
                                      name: _nameController.text.trim(),
                                      designation: _selectedDesignation!,
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
