import 'package:flutter/material.dart';
import 'package:biometric/config/constants.dart';
import 'package:biometric/screens/widgets/marquee_text.dart';

class SchoolBanner extends StatelessWidget {
  final double height; // Retained for interface backward compatibility
  final bool compact;
  final bool vertical;

  const SchoolBanner({
    Key? key,
    this.height = 160.0,
    this.compact = false,
    this.vertical = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logoWidget = Container(
      width: compact ? 84 : (vertical ? 120 : 114),
      height: compact ? 84 : (vertical ? 120 : 114),
      decoration: BoxDecoration(
        color: Colors.transparent, // Seamless transparent container backing
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.amber.withOpacity(0.6),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/school_logo.jpg',
          fit: BoxFit.cover, // Fills the entire circular area to look much larger
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFF1E1B4B),
              child: Icon(
                Icons.school_rounded,
                color: Colors.amber[300],
                size: compact ? 40 : (vertical ? 66 : 60),
              ),
            );
          },
        ),
      ),
    );

    final infoWidget = Column(
      crossAxisAlignment: vertical ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        MarqueeText(
          text: 'जवाहर माध्यमिक आश्रम शाळा',
          style: TextStyle(
            color: Colors.amber[200], // Matched golden shade
            fontSize: compact ? 16.0 : (vertical ? 21.0 : 18.5),
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 4),
        MarqueeText(
          text: '         विद्यानगर (बावी) ता.जि.धाराशिव',
          style: TextStyle(
            color: Colors.amber[200],
            fontSize: compact ? 11.5 : (vertical ? 14.0 : 13.0),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        
        // Seamless Modern Live Status Indicator
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: vertical ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppConstants.secondary, // Emerald Green
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'अधिकृत पोर्टल',
              style: TextStyle(
                color: AppConstants.textSecondary.withOpacity(0.8),
                fontSize: compact ? 9.5 : (vertical ? 11.0 : 10.5),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );

    if (vertical) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 4.0 : 8.0,
          vertical: compact ? 8.0 : 16.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            logoWidget,
            const SizedBox(height: 16),
            infoWidget,
          ],
        ),
      );
    }

    // Elegant, seamless blend with the app interface (no box/card background)
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4.0 : 8.0,
        vertical: compact ? 8.0 : 16.0,
      ),
      child: Row(
        children: [
          logoWidget,
          const SizedBox(width: 18),
          Expanded(child: infoWidget),
        ],
      ),
    );
  }
}
