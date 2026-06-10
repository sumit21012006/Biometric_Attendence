import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biometric/config/constants.dart';
import 'package:biometric/providers/auth_provider.dart';
import 'package:biometric/screens/admin/device_management.dart';
import 'package:biometric/screens/admin/logs_management.dart';
import 'package:biometric/screens/admin/settings_management.dart';
import 'package:biometric/screens/widgets/school_banner.dart';
import 'package:biometric/screens/widgets/developer_attribution.dart';
import 'package:biometric/screens/widgets/attendance_marking_view.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final email = auth.currentUser?.email ?? '';
    final isSuperAdmin = email.trim().toLowerCase() == 'sumit.m2106@gmail.com';
    final tabCount = isSuperAdmin ? 2 : 3;

    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        backgroundColor: AppConstants.background,
        appBar: AppBar(
          backgroundColor: AppConstants.cardBg,
          elevation: 4,
          title: Row(
            children: [
              const Icon(Icons.admin_panel_settings, color: AppConstants.primary, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Admin Console',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: Colors.white70),
              tooltip: 'About App & Developer',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppConstants.cardBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    title: Row(
                      children: const [
                        Icon(Icons.info_rounded, color: AppConstants.primary),
                        SizedBox(width: 10),
                        Text('About Dashboard', style: TextStyle(color: AppConstants.textPrimary)),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SchoolBanner(compact: true, vertical: true),
                        const SizedBox(height: 20),
                        const Text(
                          'Administrative Control Panel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppConstants.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Version 1.0.0 (Release Build)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 16),
                        const Center(
                          child: DeveloperAttribution(cardMode: true),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              onPressed: () => auth.signOut(),
              tooltip: 'Sign Out',
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppConstants.primary,
            indicatorWeight: 3,
            labelColor: AppConstants.textPrimary,
            unselectedLabelColor: AppConstants.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: isSuperAdmin
                ? const [
                    Tab(
                      icon: Icon(Icons.fingerprint, size: 20),
                      text: 'Attendance',
                    ),
                    Tab(
                      icon: Icon(Icons.tune, size: 20),
                      text: 'Config',
                    ),
                  ]
                : const [
                    Tab(
                      icon: Icon(Icons.fingerprint, size: 20),
                      text: 'Attendance',
                    ),
                    Tab(
                      icon: Icon(Icons.devices, size: 20),
                      text: 'Devices',
                    ),
                    Tab(
                      icon: Icon(Icons.view_headline, size: 20),
                      text: 'Logs',
                    ),
                  ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: TabBarView(
                  children: isSuperAdmin
                      ? const [
                          AttendanceMarkingView(),
                          SettingsManagementScreen(),
                        ]
                      : const [
                          AttendanceMarkingView(),
                          DeviceManagementScreen(),
                          LogsManagementScreen(),
                        ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              const DeveloperAttribution(compact: true),
            ],
          ),
        ),
      ),
    );
  }
}
