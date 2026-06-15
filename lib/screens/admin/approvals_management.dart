import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:biometric/config/constants.dart';
import 'package:biometric/models/user_model.dart';
import 'package:biometric/services/database_service.dart';
import 'package:biometric/screens/widgets/glass_card.dart';
import 'package:biometric/screens/widgets/marquee_text.dart';

class ApprovalsManagementScreen extends StatefulWidget {
  const ApprovalsManagementScreen({Key? key}) : super(key: key);

  @override
  State<ApprovalsManagementScreen> createState() => _ApprovalsManagementScreenState();
}

class _ApprovalsManagementScreenState extends State<ApprovalsManagementScreen> {
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
              hintText: 'Search pending approvals...',
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

        // Live stream list of pending employees
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: _dbService.getPendingEmployeesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppConstants.primary),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading pending users: ${snapshot.error}',
                    style: const TextStyle(color: AppConstants.accent),
                  ),
                );
              }

              final List<UserModel> pendingEmployees = snapshot.data ?? [];
              final List<UserModel> filteredEmployees = pendingEmployees.where((emp) {
                return emp.name.toLowerCase().contains(_searchQuery) ||
                    emp.email.toLowerCase().contains(_searchQuery) ||
                    emp.employeeId.toLowerCase().contains(_searchQuery);
              }).toList();

              if (filteredEmployees.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppConstants.primary.withOpacity(0.1),
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          size: 64,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty ? 'No Pending Approvals' : 'No Results Found',
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
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top row: Avatar-initial and General Name details
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppConstants.primary.withOpacity(0.15),
                                child: Text(
                                  emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: AppConstants.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    MarqueeText(
                                      text: emp.name,
                                      style: const TextStyle(
                                        color: AppConstants.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      emp.email,
                                      style: const TextStyle(
                                        color: AppConstants.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Pending Tag
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppConstants.warning.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'PENDING',
                                  style: TextStyle(
                                    color: AppConstants.warning,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Detailed User Info Card Block
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.01),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Column(
                              children: [
                                _detailRow('School Name', emp.schoolName ?? 'Not Provided'),
                                const Divider(color: Colors.white12, height: 12),
                                _detailRow('Employee ID', emp.employeeId),
                                const Divider(color: Colors.white12, height: 12),
                                _detailRow('Designation', emp.designation),
                                const Divider(color: Colors.white12, height: 12),
                                _detailRow('Sevarth ID', emp.sevarthId ?? 'Not Provided'),
                                const Divider(color: Colors.white12, height: 12),
                                _detailRow('Aadhaar Number', emp.aadhaarNumber ?? 'Not Provided'),
                                const Divider(color: Colors.white12, height: 12),
                                _detailRow(
                                  'Joining Date',
                                  emp.joiningDate != null
                                      ? DateFormat('dd MMM yyyy').format(emp.joiningDate!)
                                      : 'Not Provided',
                                ),
                                const Divider(color: Colors.white12, height: 12),
                                _detailRow(
                                  'Device ID',
                                  emp.deviceId ?? 'Not Bound',
                                  isMonospace: true,
                                ),
                                const Divider(color: Colors.white12, height: 12),
                                _detailRow(
                                  'Registered On',
                                  DateFormat('dd MMM yyyy, hh:mm a').format(emp.createdAt),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppConstants.error,
                                    side: BorderSide(color: AppConstants.error.withOpacity(0.4)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                  label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                                  onPressed: () => _confirmRejectUser(context, emp),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppConstants.success,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    elevation: 2,
                                  ),
                                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                                  label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                                  onPressed: () => _confirmApproveUser(context, emp),
                                ),
                              ),
                            ],
                          ),
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

  Widget _detailRow(String label, String value, {bool isMonospace = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              fontFamily: isMonospace ? 'monospace' : null,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Confirm and approve user
  Future<void> _confirmApproveUser(BuildContext context, UserModel emp) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified_user_rounded, color: AppConstants.success, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text('Approve Registration', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to approve the registration for ${emp.name}?\n\nThis will allow them to access the portal and log attendance.',
          style: const TextStyle(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppConstants.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _dbService.approveUser(emp.uid);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully approved employee ${emp.name}.'),
                      backgroundColor: AppConstants.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Approval failed: ${e.toString()}'),
                      backgroundColor: AppConstants.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Confirm and reject/delete user
  Future<void> _confirmRejectUser(BuildContext context, UserModel emp) async {
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
              child: Text('Reject Registration', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to reject and delete the registration for ${emp.name}?\n\nThis will delete their user record from the database, and they will need to sign up again.',
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
                await _dbService.rejectUser(emp.uid);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Rejected and deleted registration for ${emp.name}.'),
                      backgroundColor: AppConstants.accent,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Rejection failed: ${e.toString()}'),
                      backgroundColor: AppConstants.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Reject & Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
