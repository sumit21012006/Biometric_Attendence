import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:biometric/config/constants.dart';
import 'package:biometric/models/attendance_record.dart';
import 'package:biometric/services/database_service.dart';
import 'package:biometric/providers/location_provider.dart';
import 'package:biometric/screens/widgets/glass_card.dart';
import 'package:biometric/screens/widgets/premium_button.dart';
import 'package:biometric/screens/widgets/error_dialog.dart';

class LogsManagementScreen extends StatefulWidget {
  const LogsManagementScreen({Key? key}) : super(key: key);

  @override
  State<LogsManagementScreen> createState() => _LogsManagementScreenState();
}

class _LogsManagementScreenState extends State<LogsManagementScreen> {
  final DatabaseService _dbService = DatabaseService();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isExporting = false;

  Future<void> _exportExcelReport(BuildContext context) async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final sheetsUrl = locationProvider.officeConfig?.googleSheetsUrl ?? '';

    if (sheetsUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please configure the Google Sheets Web App URL in settings first.'),
          backgroundColor: AppConstants.warning,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final requestUrl = '$sheetsUrl?action=export';
      print('LogsManagementScreen: Requesting URL: $requestUrl');
      final response = await http.get(Uri.parse(requestUrl));
      
      print('LogsManagementScreen: Response Code: ${response.statusCode}');
      print('LogsManagementScreen: Response Body Preview: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] == 'success') {
          final downloadUrl = data['url'];
          
          if (await canLaunchUrl(Uri.parse(downloadUrl))) {
            await launchUrl(
              Uri.parse(downloadUrl),
              mode: LaunchMode.externalApplication,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Horizontal Excel Report generated and download started.'),
                  backgroundColor: AppConstants.success,
                ),
              );
            }
          } else {
            throw 'Could not launch browser download link: $downloadUrl';
          }
        } else {
          throw data['error'] ?? 'Spreadsheet script error';
        }
      } else {
        throw 'HTTP server returned code ${response.statusCode}';
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context,
          'Excel Export Failed',
          e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

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
              hintText: 'Search logs by employee name, email or code...',
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

        // Export Excel Button (Available for admins to download the horizontal register)
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 12.0),
          child: PremiumButton(
            text: 'Download Monthly Register',
            icon: Icons.table_view_rounded,
            gradient: AppConstants.secondaryGradient,
            isLoading: _isExporting,
            onPressed: () => _exportExcelReport(context),
          ),
        ),

        // Live stream logs
        Expanded(
          child: StreamBuilder<List<AttendanceRecord>>(
            stream: _dbService.getAllAttendanceStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppConstants.primary),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading logs: ${snapshot.error}',
                    style: const TextStyle(color: AppConstants.accent),
                  ),
                );
              }

              final List<AttendanceRecord> allLogs = snapshot.data ?? [];
              final List<AttendanceRecord> filteredLogs = allLogs.where((log) {
                return log.name.toLowerCase().contains(_searchQuery) ||
                    log.email.toLowerCase().contains(_searchQuery) ||
                    log.employeeId.toLowerCase().contains(_searchQuery) ||
                    log.designation.toLowerCase().contains(_searchQuery);
              }).toList();

              if (filteredLogs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_turned_in_outlined, size: 64, color: AppConstants.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty ? 'No Attendance Logs Found' : 'No Matching Logs',
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
                itemCount: filteredLogs.length,
                itemBuilder: (context, index) {
                  final log = filteredLogs[index];
                  final bool isCheckIn = log.type == 'check_in';
                  final String dateStr = DateFormat('MMM dd, yyyy').format(log.timestamp);
                  final String timeStr = DateFormat('hh:mm:ss a').format(log.timestamp);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GlassCard(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Employee Info Header
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log.name,
                                      style: const TextStyle(
                                        color: AppConstants.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      '${log.designation} (${log.employeeId})',
                                      style: const TextStyle(
                                        color: AppConstants.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Type Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: log.isAutoCheckout
                                      ? AppConstants.error.withOpacity(0.15)
                                      : (isCheckIn
                                          ? AppConstants.secondary.withOpacity(0.12)
                                          : AppConstants.accent.withOpacity(0.12)),
                                  borderRadius: BorderRadius.circular(8),
                                  border: log.isAutoCheckout
                                      ? Border.all(color: AppConstants.error.withOpacity(0.4), width: 1)
                                      : null,
                                ),
                                child: Text(
                                  log.isAutoCheckout
                                      ? 'AUTO OUT'
                                      : (isCheckIn ? 'IN' : 'OUT'),
                                  style: TextStyle(
                                    color: log.isAutoCheckout
                                        ? AppConstants.error
                                        : (isCheckIn ? AppConstants.secondary : AppConstants.accent),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white12, height: 16),
                          
                          if (log.isAutoCheckout) ...[
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
                                  Icon(Icons.warning_amber_rounded, color: AppConstants.error, size: 16),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Employee forgot to check out. Auto-checkout executed by system.',
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
                          
                          // Time & Distance details
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
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(
                                      color: AppConstants.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Distance info
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Distance Locked',
                                    style: TextStyle(
                                      color: Colors.white30,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '${log.distance.toStringAsFixed(1)}m from office',
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
                          
                          // Device Hardware Log Line
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Hardware: ${log.deviceId}',
                                  style: const TextStyle(
                                    color: Colors.white10,
                                    fontSize: 8.5,
                                    fontFamily: 'monospace',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'GPS: ${log.latitude.toStringAsFixed(4)}, ${log.longitude.toStringAsFixed(4)}',
                                style: const TextStyle(
                                  color: Colors.white10,
                                  fontSize: 8.5,
                                  fontFamily: 'monospace',
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
}
