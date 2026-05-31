import 'package:flutter/material.dart';
import 'package:biometric/config/constants.dart';

class LocationRadar extends StatefulWidget {
  final bool isWithinRange;
  final bool isLocating;

  const LocationRadar({
    Key? key,
    required this.isWithinRange,
    required this.isLocating,
  }) : super(key: key);

  @override
  State<LocationRadar> createState() => _LocationRadarState();
}

class _LocationRadarState extends State<LocationRadar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color coreColor = widget.isLocating
        ? AppConstants.primary
        : (widget.isWithinRange ? AppConstants.secondary : AppConstants.accent);

    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Pulse 2 (delayed/larger)
                Opacity(
                  opacity: (1.0 - _controller.value) * 0.4,
                  child: Container(
                    width: 200 * _controller.value,
                    height: 200 * _controller.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: coreColor.withOpacity(0.3),
                    ),
                  ),
                ),
                // Pulse 1
                Opacity(
                  opacity: (1.0 - _controller.value) * 0.7,
                  child: Container(
                    width: 140 * _controller.value,
                    height: 140 * _controller.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: coreColor.withOpacity(0.4),
                    ),
                  ),
                ),
                // Core center circle
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppConstants.cardBg,
                    border: Border.all(
                      color: coreColor,
                      width: 3.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: coreColor.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: widget.isLocating
                        ? const CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primary),
                          )
                        : Icon(
                            widget.isWithinRange
                                ? Icons.location_on
                                : Icons.location_off,
                            color: coreColor,
                            size: 36,
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
