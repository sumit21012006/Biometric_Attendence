import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:biometric/config/constants.dart';
import 'package:biometric/providers/auth_provider.dart';
import 'package:biometric/models/attendance_record.dart';
import 'package:biometric/services/database_service.dart';
import 'package:biometric/screens/widgets/glass_card.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  DateTime _selectedMonth = DateTime.now();
  final DatabaseService _dbService = DatabaseService();

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;

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
                stream: _dbService.getEmployeeAttendanceStream(user.uid),
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

                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Beautiful personal insights dashboard (Calendar + Legend + KPIs)
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
                      records.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.history_toggle_off_rounded, size: 48, color: AppConstants.textSecondary),
                                    SizedBox(height: 12),
                                    Text(
                                      'No Log Activities Found',
                                      style: TextStyle(
                                        color: AppConstants.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
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
                                            child: const Row(
                                              children: [
                                                Icon(Icons.warning_amber_rounded, color: AppConstants.error, size: 14),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Forgot to check out. Auto-checkout executed at 9:30 PM.',
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
                    ],
                  );
                },
              ),
      ),
    );
  }

  // Build beautiful insights & KPIs Dashboard for Employees
  Widget _buildStatsDashboard(BuildContext context, List<AttendanceRecord> records) {
    // Determine total days in the selected month
    final int year = _selectedMonth.year;
    final int month = _selectedMonth.month;
    final int daysInMonth = DateTime(year, month + 1, 0).day;
    final DateTime firstDay = DateTime(year, month, 1);
    
    // Day of week offset (0 = Sunday, 1 = Monday, ..., 6 = Saturday)
    final int offset = firstDay.weekday % 7;

    // Helper to resolve daily status
    String? getDayStatus(int d) {
      final dayRecords = records.where((r) {
        return r.timestamp.year == year &&
               r.timestamp.month == month &&
               r.timestamp.day == d;
      }).toList();

      if (dayRecords.isEmpty) {
        final date = DateTime(year, month, d);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (date.isBefore(today)) {
          return "A"; // Absent if past day
        }
        return null; // Future or today (if not marked yet)
      }

      AttendanceRecord? checkIn;
      AttendanceRecord? checkOut;

      for (var r in dayRecords) {
        if (r.type == 'check_in') {
          checkIn = r;
        } else if (r.type == 'check_out') {
          checkOut = r;
        }
      }

      // Loophole fix: Must have check-in to be anything other than Absent (A)
      if (checkIn == null) {
        return "A";
      }

      final checkInTime = checkIn.timestamp;
      final isLate = checkInTime.hour > 9 || (checkInTime.hour == 9 && checkInTime.minute > 50);

      // Update status based on check-out
      if (checkOut != null) {
        if (checkOut.isAutoCheckout) {
          return isLate ? "LF" : "F"; // Forgot checkout
        } else {
          final time = checkOut.timestamp;
          final isEarly = time.hour < 14;
          if (isEarly) {
            return "E"; // Early checkout
          }
          return isLate ? "L" : "P";
        }
      } else {
        // No checkout yet. If it is a past day, it counts as Forgot Checkout
        final date = DateTime(year, month, d);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (date.isBefore(today)) {
          return isLate ? "LF" : "F";
        }
        return isLate ? "L" : "P";
      }
    }

    // Compute month-level status counts
    int presentCount = 0;
    int absentCount = 0;
    int earlyCount = 0;
    int lateCount = 0;

    for (int d = 1; d <= daysInMonth; d++) {
      final status = getDayStatus(d);
      if (status == "P") {
        presentCount++;
      } else if (status == "A") {
        absentCount++;
      } else if (status == "E") {
        earlyCount++;
      } else if (status == "L") {
        lateCount++;
      } else if (status == "F") {
        // Option 1: Count Forgot Checkout (F) in Present Days
        presentCount++;
      } else if (status == "LF") {
        lateCount++;
        presentCount++;
      }
    }

    // Render components
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Month Selector Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: _previousMonth,
              ),
              Text(
                DateFormat('MMMM yyyy').format(_selectedMonth).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: _nextMonth,
              ),
            ],
          ),
          
          const SizedBox(height: 4),

          // Glass Card wrapping the Calendar & Legend
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Column(
              children: [
                // Weekday Headers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'].map((day) {
                    return SizedBox(
                      width: 36,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 4),
                
                // Calendar Days Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                    childAspectRatio: 1.05,
                  ),
                  itemCount: offset + daysInMonth,
                  itemBuilder: (context, index) {
                    if (index < offset) {
                      return const SizedBox.shrink(); // Empty space before 1st day of month
                    }
                    
                    final int dayNum = index - offset + 1;
                    final String? status = getDayStatus(dayNum);
                    
                    // Style attributes based on status
                    Color bg = Colors.transparent;
                    Color text = Colors.white70;
                    Border? border = Border.all(color: Colors.white12, width: 1);
                    String label = '$dayNum';

                    if (status != null) {
                      label = status;
                      border = null;
                      if (status == "P") {
                        bg = const Color(0xFFE6F4EA);
                        text = const Color(0xFF137333);
                      } else if (status == "A") {
                        bg = const Color(0xFFF1F3F4).withOpacity(0.15);
                        text = const Color(0xFF9AA0A6);
                      } else if (status == "L") {
                        bg = const Color(0xFFFFF3E0);
                        text = const Color(0xFFE65100);
                      } else if (status == "E") {
                        bg = const Color(0xFFE0F2FE);
                        text = const Color(0xFF0369a1);
                      } else if (status == "F") {
                        bg = const Color(0xFFFCE8E6);
                        text = const Color(0xFFC5221F);
                      } else if (status == "LF") {
                        bg = const Color(0xFFFEE2E2);
                        text = const Color(0xFF991B1B);
                      }
                    }

                    return Center(
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: bg,
                          shape: BoxShape.circle,
                          border: border,
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: text,
                            fontSize: status != null ? 12 : 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const Divider(color: Colors.white12, height: 12),

                // Legend row explaining P, A, L, E, F
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    _buildLegendItem("P", "Present", const Color(0xFFE6F4EA), const Color(0xFF137333)),
                    _buildLegendItem("A", "Absent", const Color(0xFFF1F3F4).withOpacity(0.15), const Color(0xFF9AA0A6)),
                    _buildLegendItem("L", "Late", const Color(0xFFFFF3E0), const Color(0xFFE65100)),
                    _buildLegendItem("E", "Early Out", const Color(0xFFE0F2FE), const Color(0xFF0369a1)),
                    _buildLegendItem("F", "Forgot Out", const Color(0xFFFCE8E6), const Color(0xFFC5221F)),
                    _buildLegendItem("LF", "Late & Forgot", const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // KPI Metric blocks (2x2 grid)
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  title: 'Present Days',
                  value: '$presentCount Days',
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF137333),
                  bg: const Color(0xFFE6F4EA),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKPICard(
                  title: 'Absent Days',
                  value: '$absentCount Days',
                  icon: Icons.cancel_outlined,
                  color: const Color(0xFF9AA0A6),
                  bg: const Color(0xFFF1F3F4).withOpacity(0.15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  title: 'Early Checkouts',
                  value: '$earlyCount Days',
                  icon: Icons.hourglass_bottom_rounded,
                  color: const Color(0xFF0369a1),
                  bg: const Color(0xFFE0F2FE),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKPICard(
                  title: 'Late Check-ins',
                  value: '$lateCount Days',
                  icon: Icons.access_time_rounded,
                  color: const Color(0xFFE65100),
                  bg: const Color(0xFFFFF3E0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String letter, String label, Color bg, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
          ),
          child: Text(
            letter,
            style: TextStyle(
              color: textColor,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppConstants.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Dashboard item card builder helper method
  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: bg,
            child: Icon(icon, color: color, size: 13),
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
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppConstants.textPrimary,
                    fontSize: 13,
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
