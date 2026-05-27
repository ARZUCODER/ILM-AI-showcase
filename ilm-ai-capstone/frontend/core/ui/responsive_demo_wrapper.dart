import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/liq_colors.dart';

class ResponsiveDemoWrapper extends StatelessWidget {
  const ResponsiveDemoWrapper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    final width = MediaQuery.of(context).size.width;
    if (width < 800) return child;

    return Scaffold(
      backgroundColor: LiqColors.bgDark,
      body: Center(
        child: Container(
          width: 390,
          height: 844,
          decoration: BoxDecoration(
            color: LiqColors.bgDeep,
            borderRadius: BorderRadius.circular(44),
            border: Border.all(color: Colors.white24, width: 8),
            boxShadow: [
              BoxShadow(
                color: LiqColors.accent.withOpacity(0.15),
                blurRadius: 80,
                spreadRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: child,
          ),
        ),
      ),
    );
  }
}