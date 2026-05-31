import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biometric/config/constants.dart';
import 'package:biometric/providers/auth_provider.dart';
import 'package:biometric/screens/admin/device_management.dart';
import 'package:biometric/screens/admin/logs_management.dart';
import 'package:biometric/screens/admin/settings_management.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppConstants.background,
        appBar: AppBar(
          backgroundColor: AppConstants.cardBg,
          elevation: 4,
          title: Row(
            children: const [
              Icon(Icons.admin_panel_settings, color: AppConstants.primary, size: 28),
              SizedBox(width: 8),
              Text(
                'Admin Console',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              onPressed: () => auth.signOut(),
              tooltip: 'Sign Out',
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppConstants.primary,
            indicatorWeight: 3,
            labelColor: AppConstants.textPrimary,
            unselectedLabelColor: AppConstants.textSecondary,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(
                icon: Icon(Icons.devices, size: 20),
                text: 'Devices',
              ),
              Tab(
                icon: Icon(Icons.view_headline, size: 20),
                text: 'Logs',
              ),
              Tab(
                icon: Icon(Icons.tune, size: 20),
                text: 'Config',
              ),
            ],
          ),
        ),
        body: const SafeArea(
          child: TabBarView(
            children: [
              DeviceManagementScreen(),
              LogsManagementScreen(),
              SettingsManagementScreen(),
            ],
          ),
        ),
      ),
    );
  }
}
