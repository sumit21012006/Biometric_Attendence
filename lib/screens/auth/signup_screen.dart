import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:biometric/config/constants.dart';
import 'package:biometric/providers/auth_provider.dart';
import 'package:biometric/providers/location_provider.dart';
import 'package:biometric/screens/widgets/glass_card.dart';
import 'package:biometric/screens/widgets/premium_button.dart';
import 'package:biometric/screens/widgets/school_banner.dart';
import 'package:biometric/screens/widgets/developer_attribution.dart';
import 'package:biometric/main.dart';
import 'package:biometric/screens/widgets/error_dialog.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _sevarthIdController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _joiningDateController = TextEditingController();
  DateTime? _selectedJoiningDate;
  String? _selectedDesignation;
  String? _selectedSchoolName;

  // Curated list of schools
  final List<String> _schools = [
    'Vasant Primary Ashram School',
    'Jawahar Secondary Ashram School',
    'Jawahar Junior college',
    'Indira Gandi Boys Hostel',
    'Soba Naik Balgruh',
  ];

  // Curated list of official job designations
  final List<String> _designations = [
    'Head Master',
    'Higher Secondary Teacher',
    'Secondary Teacher',
    'Primary Teacher',
    'Clerk',
    'Non teaching staff (School)',
    'Hostel Rector',
    'Non teaching staff (Hostel)',
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
    _sevarthIdController.dispose();
    _aadhaarController.dispose();
    _joiningDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);

    final email = auth.tempGoogleUser?.email ?? '';
    var adminEmails = locationProvider.officeConfig?.adminEmails ?? [];
    if (adminEmails.isEmpty) {
      adminEmails = AppConstants.defaultAdminEmails;
    }
    final isDefaultAdmin = AppConstants.defaultAdminEmails.any((e) => e.trim().toLowerCase() == email.trim().toLowerCase());
    final isAdmin = isDefaultAdmin || adminEmails.any((e) => e.trim().toLowerCase() == email.trim().toLowerCase());

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
                      // School Branding Banner
                      const SchoolBanner(compact: true),
                      const SizedBox(height: 24),
                      Text(
                        isAdmin ? 'Admin Portal Setup' : 'Complete Profile Onboarding',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAdmin
                            ? 'Your email has been pre-authorized. Confirm your name to setup your admin console.'
                            : 'Please submit your school registration details to bind this device to your staff account.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Form input container card
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (isAdmin) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppConstants.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppConstants.primary.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.shield_outlined, color: AppConstants.primary, size: 24),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Admin Account Pre-authorized',
                                            style: TextStyle(
                                              color: AppConstants.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Your email is registered for administrative access.',
                                            style: TextStyle(
                                              color: AppConstants.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

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

                            if (!isAdmin) ...[
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
                                textCapitalization: TextCapitalization.characters,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(4),
                                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                                ],
                                decoration: InputDecoration(
                                  hintText: 'e.g. H001',
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
                                  final cleaned = value.trim().toUpperCase();
                                  if (!RegExp(r'^[A-Z][0-9]{3}$').hasMatch(cleaned)) {
                                    return 'Must be a letter followed by 3 digits (e.g. H001)';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Custom Input field: Sevarth ID
                              const Text(
                                'Sevarth ID',
                                style: TextStyle(
                                  color: AppConstants.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _sevarthIdController,
                                style: const TextStyle(color: AppConstants.textPrimary),
                                textCapitalization: TextCapitalization.characters,
                                inputFormatters: [
                                  TextInputFormatter.withFunction((oldValue, newValue) {
                                    return newValue.copyWith(text: newValue.text.toUpperCase());
                                  }),
                                ],
                                decoration: InputDecoration(
                                  hintText: 'Enter your 12-char Sevarth ID',
                                  hintStyle: const TextStyle(color: AppConstants.textSecondary),
                                  prefixIcon: const Icon(Icons.assignment_ind_rounded, color: AppConstants.primary),
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
                                    return 'Please enter your Sevarth ID';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Custom Input field: Aadhaar Number
                              const Text(
                                'Aadhaar Number',
                                style: TextStyle(
                                  color: AppConstants.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _aadhaarController,
                                style: const TextStyle(color: AppConstants.textPrimary),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Enter 12-digit Aadhaar number',
                                  hintStyle: const TextStyle(color: AppConstants.textSecondary),
                                  prefixIcon: const Icon(Icons.fingerprint_rounded, color: AppConstants.primary),
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
                                    return 'Please enter your Aadhaar number';
                                  }
                                  final cleaned = value.trim().replaceAll(RegExp(r'\s+'), '');
                                  if (cleaned.length != 12 || double.tryParse(cleaned) == null) {
                                    return 'Please enter a valid 12-digit Aadhaar number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Custom Dropdown field: School Name
                              const Text(
                                'School Name',
                                style: TextStyle(
                                  color: AppConstants.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedSchoolName,
                                isExpanded: true,
                                dropdownColor: AppConstants.cardBg,
                                style: const TextStyle(color: AppConstants.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'Select School Name',
                                  hintStyle: const TextStyle(color: AppConstants.textSecondary),
                                  prefixIcon: const Icon(Icons.school_rounded, color: AppConstants.primary),
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
                                items: _schools.map((school) {
                                  return DropdownMenuItem<String>(
                                    value: school,
                                    child: Text(
                                      school,
                                      style: const TextStyle(color: AppConstants.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSchoolName = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select your school';
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
                                isExpanded: true,
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
                                      overflow: TextOverflow.ellipsis,
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
                              const SizedBox(height: 20),

                              // Custom Input field: Joining Date
                              const Text(
                                'Joining Date',
                                style: TextStyle(
                                  color: AppConstants.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _joiningDateController,
                                style: const TextStyle(color: AppConstants.textPrimary),
                                readOnly: true,
                                decoration: InputDecoration(
                                  hintText: 'Select your joining date',
                                  hintStyle: const TextStyle(color: AppConstants.textSecondary),
                                  prefixIcon: const Icon(Icons.calendar_month_rounded, color: AppConstants.primary),
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
                                onTap: () async {
                                  final DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedJoiningDate ?? DateTime.now(),
                                    firstDate: DateTime(1970),
                                    lastDate: DateTime.now(),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.dark(
                                            primary: AppConstants.primary,
                                            onPrimary: Colors.white,
                                            surface: AppConstants.cardBg,
                                            onSurface: AppConstants.textPrimary,
                                          ),
                                          dialogBackgroundColor: AppConstants.background,
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (pickedDate != null) {
                                    setState(() {
                                      _selectedJoiningDate = pickedDate;
                                      _joiningDateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
                                    });
                                  }
                                },
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please select your joining date';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),
                            ],

                            // Submit Button
                            PremiumButton(
                              text: isAdmin ? 'Register Admin Account' : 'Register Account',
                              icon: Icons.check_circle_outline_rounded,
                              gradient: AppConstants.secondaryGradient,
                              isLoading: auth.isLoading,
                              onPressed: () async {
                                if (_formKey.currentState!.validate() && (isAdmin || (_selectedDesignation != null && _selectedJoiningDate != null && _selectedSchoolName != null))) {
                                  try {
                                    if (isAdmin) {
                                      await auth.signUpAdmin(
                                        name: _nameController.text.trim(),
                                      );
                                    } else {
                                      await auth.signUpEmployee(
                                        name: _nameController.text.trim(),
                                        designation: _selectedDesignation!,
                                        employeeId: _employeeIdController.text.trim().toUpperCase(),
                                        sevarthId: _sevarthIdController.text.trim().toUpperCase(),
                                        aadhaarNumber: _aadhaarController.text.trim(),
                                        joiningDate: _selectedJoiningDate!,
                                        schoolName: _selectedSchoolName!,
                                      );
                                    }
                                    if (mounted) {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: AppConstants.cardBg,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                          title: const Row(
                                            children: [
                                              Icon(Icons.check_circle_rounded, color: AppConstants.secondary, size: 28),
                                              SizedBox(width: 10),
                                              Text(
                                                'Success',
                                                style: TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          content: Text(
                                            isAdmin
                                                ? 'Your administrative account has been registered successfully. Directing to admin panel...'
                                                : 'Your staff account has been registered successfully. Directing to your portal...',
                                            style: const TextStyle(color: AppConstants.textSecondary, fontSize: 13, height: 1.45),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context); // Close dialog
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => const AuthSessionGate()),
                                                );
                                              },
                                              child: const Text(
                                                'OK',
                                                style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    showErrorDialog(
                                      context,
                                      'Registration Failed',
                                      e.toString(),
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
                      const SizedBox(height: 16),
                      const DeveloperAttribution(compact: true),
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
