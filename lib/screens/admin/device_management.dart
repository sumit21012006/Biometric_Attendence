import 'package:flutter/material.dart';
import 'package:biometric/config/constants.dart';
import 'package:biometric/models/user_model.dart';
import 'package:biometric/services/database_service.dart';
import 'package:biometric/screens/widgets/glass_card.dart';
import 'package:biometric/screens/widgets/marquee_text.dart';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({Key? key}) : super(key: key);

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  final DatabaseService _dbService = DatabaseService();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: AppConstants.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search employees by name or email...',
              hintStyle: const TextStyle(color: AppConstants.textSecondary),
              prefixIcon: const Icon(Icons.search, color: AppConstants.primary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppConstants.cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase().trim();
              });
            },
          ),
        ),

        // Live stream list
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: _dbService.getEmployeesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppConstants.primary),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading users: ${snapshot.error}',
                    style: const TextStyle(color: AppConstants.accent),
                  ),
                );
              }

              final List<UserModel> allEmployees = snapshot.data ?? [];
              final List<UserModel> filteredEmployees = allEmployees.where((emp) {
                return emp.name.toLowerCase().contains(_searchQuery) ||
                    emp.email.toLowerCase().contains(_searchQuery) ||
                    emp.employeeId.toLowerCase().contains(_searchQuery);
              }).toList();

              if (filteredEmployees.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline, size: 64, color: AppConstants.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty ? 'No Employees Registered' : 'No Results Found',
                        style: const TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                itemCount: filteredEmployees.length,
                itemBuilder: (context, index) {
                  final emp = filteredEmployees[index];
                  final bool isBound = emp.deviceId != null && emp.deviceId!.isNotEmpty;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Profile details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: MarqueeText(
                                        text: emp.name,
                                        style: const TextStyle(
                                          color: AppConstants.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Device lock status chip
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isBound
                                            ? AppConstants.secondary.withOpacity(0.12)
                                            : AppConstants.warning.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isBound ? 'LOCKED' : 'UNBOUND',
                                        style: TextStyle(
                                          color: isBound ? AppConstants.secondary : AppConstants.warning,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${emp.designation} (${emp.employeeId})',
                                  style: const TextStyle(
                                    color: AppConstants.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  emp.schoolName ?? 'N/A',
                                  style: const TextStyle(
                                    color: AppConstants.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  emp.email,
                                  style: const TextStyle(
                                    color: Colors.white30,
                                    fontSize: 12,
                                  ),
                                ),
                                if (isBound) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Device ID: ${emp.deviceId}',
                                    style: const TextStyle(
                                      color: Colors.white24,
                                      fontSize: 9,
                                      fontFamily: 'monospace',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          // Reset button
                          if (isBound) ...[
                            IconButton(
                              icon: const Icon(Icons.phonelink_erase_rounded, color: AppConstants.accent),
                              tooltip: 'Reset Device Lock',
                              onPressed: () => _confirmResetDevice(context, emp),
                            ),
                          ] else ...[
                            const Icon(Icons.phonelink_setup_rounded, color: Colors.white30),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Trigger device reset confirmation prompt
  Future<void> _confirmResetDevice(BuildContext context, UserModel emp) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppConstants.accent, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text('Reset Device Lock', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to unbind the device for ${emp.name}?\n\nThis will allow them to register and lock their account onto a new mobile device during their next login.',
          style: const TextStyle(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppConstants.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _dbService.updateDeviceId(emp.uid, null);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully reset device binding for ${emp.name}.'),
                      backgroundColor: AppConstants.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reset failed: ${e.toString()}'),
                      backgroundColor: AppConstants.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
