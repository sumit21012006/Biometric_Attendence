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

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Beautiful personal insights dashboard
                      _buildStatsDashboard(context, records),
                      
                      // Section Header
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                        child: Text(
                          'Recent Log Activities',
                          style: TextStyle(
                            color: AppConstants.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      // Logs List
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
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
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  // Build beautiful insights & KPIs Dashboard for Employees
  Widget _buildStatsDashboard(BuildContext context, List<AttendanceRecord> records) {
    // 1. Calculate stats from history records
    final uniqueDays = records
        .map((r) => DateFormat('yyyy-MM-dd').format(r.timestamp))
        .toSet()
        .length;
    final checkInCount = records.where((r) => r.type == 'check_in').length;
    final forgotCheckOuts = records.where((r) => r.isAutoCheckout).length;
    
    final verifiedCount = records.where((r) => r.verified).length;
    final verificationRate = records.isNotEmpty
        ? (verifiedCount / records.length * 100).toInt()
        : 100;
        
    final avgDistance = records.isNotEmpty
        ? records.map((r) => r.distance).reduce((a, b) => a + b) / records.length
        : 0.0;

    // Calculate dynamic consistency percentage
    final double consistencyVal = checkInCount == 0
        ? 1.0
        : (1.0 - (forgotCheckOuts / checkInCount)).clamp(0.0, 1.0);
    final int consistencyPercentage = (consistencyVal * 100).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Flawless status summary card
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.primary.withOpacity(0.9),
                  AppConstants.primary.withOpacity(0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white24, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primary.withOpacity(0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MY PERFORMANCE METER',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        forgotCheckOuts == 0 ? 'Flawless Profile' : 'Attention Required',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        forgotCheckOuts == 0
                            ? 'Excellent consistency! Keep checking out daily.'
                            : 'Remember to check out at shift ends to avoid automated logs.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        value: consistencyVal,
                        strokeWidth: 7,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          forgotCheckOuts == 0 ? AppConstants.secondary : AppConstants.warning,
                        ),
                      ),
                    ),
                    Text(
                      '$consistencyPercentage%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 14),
          
          // KPI Metric Items Grid (2x2 Row blocks)
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  title: 'Working Days',
                  value: '$uniqueDays Days',
                  icon: Icons.calendar_month_outlined,
                  color: AppConstants.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKPICard(
                  title: 'Security Verify',
                  value: '$verificationRate%',
                  icon: Icons.fingerprint_rounded,
                  color: AppConstants.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  title: 'Forgot Out',
                  value: '$forgotCheckOuts times',
                  icon: Icons.warning_amber_rounded,
                  color: forgotCheckOuts > 0 ? AppConstants.error : AppConstants.textSecondary,
                  alertMode: forgotCheckOuts > 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKPICard(
                  title: 'Avg. Accuracy',
                  value: '${avgDistance.toStringAsFixed(1)}m',
                  icon: Icons.map_outlined,
                  color: AppConstants.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Dashboard item card builder helper method
  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool alertMode = false,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: alertMode ? AppConstants.error : AppConstants.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
