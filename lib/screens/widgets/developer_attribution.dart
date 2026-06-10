import 'package:flutter/material.dart';
import 'package:biometric/config/constants.dart';

class DeveloperAttribution extends StatelessWidget {
  final bool cardMode;
  final bool compact;

  const DeveloperAttribution({
    Key? key,
    this.cardMode = false,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (cardMode) {
      // Elegant detail card layout for dashboard info tabs or profile areas
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.code_rounded,
                color: AppConstants.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Application Developer',
                    style: TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'SUMIT PURUSHOTTAM MANE',
                      style: TextStyle(
                        color: AppConstants.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Classic subtle bottom bar signature footer
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: compact ? 6.0 : 12.0),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.terminal_rounded,
                size: compact ? 12 : 14,
                color: AppConstants.primary.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                'Developed by ',
                style: TextStyle(
                  color: AppConstants.textSecondary.withOpacity(0.7),
                  fontSize: compact ? 10.5 : 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'SUMIT PURUSHOTTAM MANE',
                style: TextStyle(
                  color: AppConstants.primary.withOpacity(0.85),
                  fontSize: compact ? 11.0 : 12.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.favorite_rounded,
                size: compact ? 10 : 12,
                color: AppConstants.accent.withOpacity(0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
