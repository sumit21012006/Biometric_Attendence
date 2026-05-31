import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:biometric/config/constants.dart';
import 'package:biometric/providers/auth_provider.dart';
import 'package:biometric/models/attendance_record.dart';
import 'package:biometric/services/database_service.dart';
import 'package:biometric/screens/widgets/glass_card.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    final dbService = DatabaseService();

    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Attendance Logs',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: user == null
            ? const Center(child: Text('Session Error', style: TextStyle(color: Colors.white)))
            : StreamBuilder<List<AttendanceRecord>>(
                stream: dbService.getEmployeeAttendanceStream(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppConstants.primary),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading records: ${snapshot.error}',
                        style: const TextStyle(color: AppConstants.accent),
                      ),
                    );
                  }

                  final List<AttendanceRecord> records = snapshot.data ?? [];

                  if (records.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off_rounded, size: 64, color: AppConstants.textSecondary),
                          const SizedBox(height: 16),
                          const Text(
                            'No Attendance Logs Found',
                            style: TextStyle(
                              color: AppConstants.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Your marked check-ins and check-outs will appear here.',
                            style: TextStyle(color: AppConstants.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      final bool isCheckIn = record.type == 'check_in';
                      final String dateStr = DateFormat('EEE, MMM d, y').format(record.timestamp);
                      final String timeStr = DateFormat('hh:mm a').format(record.timestamp);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Log Type Badge (In / Out)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: record.isAutoCheckout
                                          ? AppConstants.error.withOpacity(0.15)
                                          : (isCheckIn
                                              ? AppConstants.secondary.withOpacity(0.12)
                                              : AppConstants.accent.withOpacity(0.12)),
                                      borderRadius: BorderRadius.circular(10),
                                      border: record.isAutoCheckout
                                          ? Border.all(color: AppConstants.error.withOpacity(0.4), width: 1)
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          record.isAutoCheckout
                                              ? Icons.warning_amber_rounded
                                              : (isCheckIn ? Icons.login_rounded : Icons.logout_rounded),
                                          color: record.isAutoCheckout
                                              ? AppConstants.error
                                              : (isCheckIn ? AppConstants.secondary : AppConstants.accent),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          record.isAutoCheckout
                                              ? 'AUTO CHECK OUT'
                                              : (isCheckIn ? 'CHECK IN' : 'CHECK OUT'),
                                          style: TextStyle(
                                            color: record.isAutoCheckout
                                                ? AppConstants.error
                                                : (isCheckIn ? AppConstants.secondary : AppConstants.accent),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Verification Badge
                                  Row(
                                    children: [
                                      Icon(
                                        record.isAutoCheckout ? Icons.info_outline : Icons.verified_user,
                                        color: record.isAutoCheckout ? AppConstants.error : AppConstants.secondary,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        record.isAutoCheckout ? 'System Auto' : 'Verified',
                                        style: TextStyle(
                                          color: record.isAutoCheckout ? AppConstants.error : AppConstants.secondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white12, height: 20),
                              
                              if (record.isAutoCheckout) ...[
                                Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppConstants.error.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppConstants.error.withOpacity(0.2), width: 1),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.warning_amber_rounded, color: AppConstants.error, size: 14),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Forgot to check out. Auto-checkout executed at 6:00 PM.',
                                          style: TextStyle(
                                            color: AppConstants.error,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              
                              // Log Information
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dateStr,
                                        style: const TextStyle(
                                          color: AppConstants.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        timeStr,
                                        style: const TextStyle(
                                          color: AppConstants.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // Distance indicators
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Accuracy Dist.',
                                        style: TextStyle(
                                          color: AppConstants.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${record.distance.toStringAsFixed(1)}m from office',
                                        style: const TextStyle(
                                          color: AppConstants.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              
                              // Device serial logs
                              Text(
                                'Hardware: ${record.deviceId}',
                                style: const TextStyle(
                                  color: Colors.white24,
                                  fontSize: 9,
                                  fontFamily: 'monospace',
                                ),
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
    );
  }
}
