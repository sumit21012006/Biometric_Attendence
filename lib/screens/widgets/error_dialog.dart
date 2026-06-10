import 'package:flutter/material.dart';
import 'package:biometric/config/constants.dart';

void showErrorDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppConstants.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: const [
          Icon(Icons.error_outline_rounded, color: AppConstants.accent, size: 28),
          SizedBox(width: 10),
          Text(
            'Alert',
            style: TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(
                color: AppConstants.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            message,
            style: const TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Dismiss',
            style: TextStyle(color: AppConstants.primary, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
