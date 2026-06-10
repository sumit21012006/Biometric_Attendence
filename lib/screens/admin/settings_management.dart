import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:biometric/config/constants.dart';
import 'package:biometric/models/office_config.dart';
import 'package:biometric/providers/location_provider.dart';
import 'package:biometric/screens/widgets/glass_card.dart';
import 'package:biometric/screens/widgets/premium_button.dart';

class SettingsManagementScreen extends StatefulWidget {
  const SettingsManagementScreen({Key? key}) : super(key: key);

  @override
  State<SettingsManagementScreen> createState() => _SettingsManagementScreenState();
}

class _SettingsManagementScreenState extends State<SettingsManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _radiusController = TextEditingController();
  final _sheetsUrlController = TextEditingController();
  final _newEmailController = TextEditingController();

  final List<String> _adminEmails = [];
  bool _isLocatingCurrent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = Provider.of<LocationProvider>(context, listen: false).officeConfig;
      if (config != null) {
        _populateFields(config);
      }
    });
  }

  void _populateFields(OfficeConfig config) {
    _latitudeController.text = config.latitude.toString();
    _longitudeController.text = config.longitude.toString();
    _radiusController.text = config.radius.toString();
    _sheetsUrlController.text = config.googleSheetsUrl;
    setState(() {
      _adminEmails.clear();
      _adminEmails.addAll(config.adminEmails);
    });
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _radiusController.dispose();
    _sheetsUrlController.dispose();
    _newEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);

    // Repopulate if config finishes loading late
    if (!_isLocatingCurrent &&
        _latitudeController.text.isEmpty &&
        locationProvider.officeConfig != null) {
      _populateFields(locationProvider.officeConfig!);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Settings header info
            const Text(
              'Office & Sheets Setup',
              style: TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Define geofence coordinates and establish real-time connections to Google Sheets spreadsheets.',
              style: TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Configurations Box
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Geofence Coordinate Fields
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Office Latitude',
                              style: TextStyle(color: AppConstants.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _latitudeController,
                              style: const TextStyle(color: AppConstants.textPrimary),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: _inputDecoration('e.g. 28.6139'),
                              validator: (v) => _validateDouble(v, 'Invalid Latitude'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Office Longitude',
                              style: TextStyle(color: AppConstants.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _longitudeController,
                              style: const TextStyle(color: AppConstants.textPrimary),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: _inputDecoration('e.g. 77.2090'),
                              validator: (v) => _validateDouble(v, 'Invalid Longitude'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Shortcut GPS Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primary.withOpacity(0.15),
                      foregroundColor: AppConstants.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: _isLocatingCurrent
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.primary),
                          )
                        : const Icon(Icons.my_location, size: 18),
                    label: const Text(
                      'Use My Current GPS Position',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isLocatingCurrent ? null : _setCurrentGpsPosition,
                  ),
                  
                  const Divider(color: Colors.white12, height: 32),

                  // Radius Config
                  const Text(
                    'Office Geofence Radius (meters)',
                    style: TextStyle(color: AppConstants.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _radiusController,
                    style: const TextStyle(color: AppConstants.textPrimary),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDecoration('e.g. 100'),
                    validator: (v) => _validateDouble(v, 'Invalid Radius'),
                  ),
                  
                  const Divider(color: Colors.white12, height: 32),

                  // Google Sheets Web App URL
                  const Text(
                    'Google Sheets Web App URL',
                    style: TextStyle(color: AppConstants.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _sheetsUrlController,
                    style: const TextStyle(color: AppConstants.textPrimary),
                    keyboardType: TextInputType.url,
                    decoration: _inputDecoration('https://script.google.com/macros/s/.../exec'),
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        if (!v.startsWith('https://script.google.com')) {
                          return 'Must be a valid Google Apps Script script URL';
                        }
                      }
                      return null;
                    },
                  ),
                  
                  const Divider(color: Colors.white12, height: 32),

                  // Admin Access Emails Section
                  Row(
                    children: const [
                      Icon(Icons.admin_panel_settings, color: AppConstants.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Admin Access Emails',
                        style: TextStyle(color: AppConstants.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Designate email addresses that have administrative console privileges. These users will bypass device-binding constraints.',
                    style: TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Add New Email Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _newEmailController,
                          style: const TextStyle(color: AppConstants.textPrimary, fontSize: 13),
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration('e.g. admin@school.com'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onPressed: () {
                          final email = _newEmailController.text.trim();
                          if (email.isNotEmpty) {
                            if (!email.contains('@')) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a valid email address.'),
                                  backgroundColor: AppConstants.error,
                                ),
                              );
                              return;
                            }
                            if (_adminEmails.any((e) => e.toLowerCase() == email.toLowerCase())) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Email is already in the list.'),
                                  backgroundColor: AppConstants.warning,
                                ),
                              );
                              return;
                            }
                            setState(() {
                              _adminEmails.add(email);
                              _newEmailController.clear();
                            });
                          }
                        },
                        child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Admin Emails List container
                  if (_adminEmails.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.01),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: const Center(
                        child: Text(
                          'No admin emails designated yet.',
                          style: TextStyle(color: AppConstants.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.01),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: _adminEmails.length,
                          separatorBuilder: (context, index) => const Divider(color: Colors.white12, height: 1),
                          itemBuilder: (context, index) {
                            final email = _adminEmails[index];
                            final isSuperAdmin = email.trim().toLowerCase() == 'sumit.m2106@gmail.com';
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.mail_outline, size: 16, color: AppConstants.textSecondary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      email,
                                      style: const TextStyle(color: AppConstants.textPrimary, fontSize: 13),
                                    ),
                                  ),
                                  if (isSuperAdmin)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppConstants.primary.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Owner',
                                        style: TextStyle(color: AppConstants.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  else
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppConstants.error, size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        setState(() {
                                          _adminEmails.removeAt(index);
                                        });
                                      },
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 32),

                  // Save configuration button
                  PremiumButton(
                    text: 'Save Configurations',
                    icon: Icons.save_rounded,
                    gradient: AppConstants.primaryGradient,
                    isLoading: locationProvider.isLoading,
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final newConfig = OfficeConfig(
                          latitude: double.parse(_latitudeController.text),
                          longitude: double.parse(_longitudeController.text),
                          radius: double.parse(_radiusController.text),
                          googleSheetsUrl: _sheetsUrlController.text.trim(),
                          adminEmails: _adminEmails,
                        );
                        
                        try {
                          await locationProvider.updateOfficeConfig(newConfig);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Configurations saved and synced successfully.'),
                                backgroundColor: AppConstants.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Save failed: ${e.toString()}'),
                                backgroundColor: AppConstants.error,
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Input styling
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppConstants.primary),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.01),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  // Validators
  String? _validateDouble(String? value, String errorMsg) {
    if (value == null || value.isEmpty) return 'Field cannot be empty';
    final parsed = double.tryParse(value);
    if (parsed == null) return errorMsg;
    return null;
  }

  // Fetch current coordinates and set form fields
  Future<void> _setCurrentGpsPosition() async {
    setState(() => _isLocatingCurrent = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied.';
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
        _isLocatingCurrent = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Updated coordinates to current GPS position.'),
            backgroundColor: AppConstants.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLocatingCurrent = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get coordinates: ${e.toString()}'),
            backgroundColor: AppConstants.error,
          ),
        );
      }
    }
  }
}
