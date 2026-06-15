import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:biometric/config/constants.dart';
import 'package:biometric/providers/auth_provider.dart';
import 'package:biometric/providers/location_provider.dart';
import 'package:biometric/providers/attendance_provider.dart';
import 'package:biometric/screens/employee/attendance_history.dart';
import 'package:biometric/screens/widgets/glass_card.dart';
import 'package:biometric/screens/widgets/premium_button.dart';
import 'package:biometric/screens/widgets/location_radar.dart';
import 'package:biometric/screens/widgets/school_banner.dart';
import 'package:biometric/screens/widgets/developer_attribution.dart';
import 'package:biometric/screens/widgets/error_dialog.dart';

class AttendanceMarkingView extends StatefulWidget {
  const AttendanceMarkingView({Key? key}) : super(key: key);

  @override
  State<AttendanceMarkingView> createState() => _AttendanceMarkingViewState();
}

class _AttendanceMarkingViewState extends State<AttendanceMarkingView> {
  @override
  void initState() {
    super.initState();
    // Proactively verify geofence coordinate location when loading view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LocationProvider>(context, listen: false).verifyGeofence();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final location = Provider.of<LocationProvider>(context);
    final attendance = Provider.of<AttendanceProvider>(context);
    final user = auth.currentUser;

    final String dateStr = DateFormat('EEEE, MMMM d, y').format(DateTime.now());

    return RefreshIndicator(
      onRefresh: () async {
        location.resetLocation();
        await location.verifyGeofence();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // School Branding Banner
            const SchoolBanner(compact: true),
            const SizedBox(height: 16),

            // Welcome Profile Card
            GlassCard(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppConstants.primary.withOpacity(0.2),
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name.substring(0, 1).toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Name',
                          style: const TextStyle(
                            color: AppConstants.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.designation ?? 'Role',
                          style: const TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.employeeId ?? 'ID',
                          style: const TextStyle(
                            color: AppConstants.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Radar Location Scanner Box
            GlassCard(
              child: Column(
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Custom pulsating radar
                  LocationRadar(
                    isWithinRange: location.isWithinRange,
                    isLocating: location.isLoading,
                  ),
                  const SizedBox(height: 16),

                  // Location Details Badge
                  if (location.isLoading) ...[
                    const Text(
                      'Locating device GPS satellites...',
                      style: TextStyle(color: AppConstants.textSecondary, fontSize: 13),
                    ),
                  ] else if (location.distanceFromOffice >= 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: location.isWithinRange
                            ? AppConstants.secondary.withOpacity(0.1)
                            : AppConstants.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: location.isWithinRange
                              ? AppConstants.secondary.withOpacity(0.3)
                              : AppConstants.accent.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            location.isWithinRange
                                ? 'PRESENCE VERIFIED'
                                : 'OUT OF RANGE',
                            style: TextStyle(
                              color: location.isWithinRange
                                  ? AppConstants.secondary
                                  : AppConstants.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            location.isWithinRange
                                ? 'You are within the designated office perimeter.'
                                : 'You are ${location.distanceFromOffice.toStringAsFixed(1)}m away from office.',
                            style: const TextStyle(
                              color: AppConstants.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Text(
                      location.locationError.isNotEmpty
                          ? location.locationError
                          : 'GPS location lock not acquired.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppConstants.accent, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => location.verifyGeofence(),
                      icon: const Icon(Icons.gps_fixed, size: 16),
                      label: const Text('Retry GPS Lock'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Check In and Check Out Actions
            Row(
              children: [
                Expanded(
                  child: PremiumButton(
                    text: 'Check In',
                    icon: Icons.login,
                    isLoading: attendance.isProcessing,
                    gradient: AppConstants.secondaryGradient,
                    onPressed: !location.isWithinRange || attendance.isProcessing
                        ? null
                        : () => _triggerAttendance('check_in', auth, location, attendance),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PremiumButton(
                    text: 'Check Out',
                    icon: Icons.logout,
                    isLoading: attendance.isProcessing,
                    gradient: AppConstants.accentGradient,
                    onPressed: !location.isWithinRange || attendance.isProcessing
                        ? null
                        : () => _triggerAttendance('check_out', auth, location, attendance),
                  ),
                ),
              ],
            ),
            
            if (attendance.statusMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                attendance.statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: attendance.operationSuccess
                      ? AppConstants.secondary
                      : AppConstants.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Link to Personal History Screen
            PremiumButton(
              text: 'View Attendance Logs',
              icon: Icons.history_rounded,
              color: AppConstants.cardBg,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()),
                );
              },
            ),
            const SizedBox(height: 28),
            const Center(
              child: DeveloperAttribution(cardMode: true),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Orchestrator method to run biometric local authentication and post parameters
  Future<void> _triggerAttendance(
    String type,
    AuthProvider auth,
    LocationProvider location,
    AttendanceProvider attendance,
  ) async {
    attendance.clearStatus();
    final bool success = await attendance.markAttendance(
      authProvider: auth,
      locationProvider: location,
      type: type,
    );

    if (mounted) {
      if (success) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppConstants.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppConstants.secondary, size: 30),
                SizedBox(width: 10),
                Text('Success', style: TextStyle(color: AppConstants.textPrimary)),
              ],
            ),
            content: Text(
              'Attendance marked successfully for ${type == "check_in" ? "Check-In" : "Check-Out"}.\n\nRecords synchronized to database and Google Sheets.',
              style: const TextStyle(color: AppConstants.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  attendance.clearStatus();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        showErrorDialog(
          context,
          'Attendance Marking Failed',
          attendance.statusMessage,
        );
      }
    }
  }
}
