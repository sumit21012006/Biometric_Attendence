import 'package:flutter/material.dart';

class AppConstants {
  // Application branding
  static const String appName = 'BioLocation Attendance';

  // Harmonized HSL / Premium Theme Colors
  static const Color primary = Color(0xFF6366F1);      // Vibrant Indigo
  static const Color secondary = Color(0xFF10B981);    // Emerald Green
  static const Color accent = Color(0xFFF43F5E);       // Rose Red
  static const Color background = Color(0xFF0F172A);   // Deep Slate Dark background
  static const Color cardBg = Color(0xFF1E293B);       // Lighter Slate for Cards
  static const Color textPrimary = Color(0xFFF8FAFC);  // Crisp Off-White
  static const Color textSecondary = Color(0xFF94A3B8); // Soft Muted Gray
  static const Color success = Color(0xFF10B981);      // Green success
  static const Color warning = Color(0xFFF59E0B);      // Amber alert
  static const Color error = Color(0xFFEF4444);        // Crimson error

  // Beautiful modern gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Office Location Fallbacks (if config is not fetched yet)
  static const double defaultOfficeLatitude = 28.6139;  // e.g. New Delhi
  static const double defaultOfficeLongitude = 77.2090;
  static const double defaultOfficeRadius = 100.0;      // In meters

  // Default Admin Emails
  static const List<String> defaultAdminEmails = [
    'sumit.m2106@gmail.com',
    'admin@example.com',
  ];

  // Web Client ID from google-services.json (OAuth client_type 3)
  static const String webClientId = '943010912638-mevn797vtvd2air2bbq7nna4gaboomda.apps.googleusercontent.com';

  // Custom shadows
  static List<BoxShadow> premiumShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 15,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: primary.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];
}
