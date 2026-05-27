import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/liq_colors.dart';

/// Animated aurora gradient backdrop. Provides the depth that makes the
/// glass surfaces feel alive – soft floating blobs of colour, with grain
/// of darkness underneath.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({
    super.key,
    required this.child,
    this.palette,
    this.intensity = 1.0,
  });

  final Widget child;
  final List<Color>? palette;
  final double intensity;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette ??
        const [
          LiqColors.auroraGreen,
          LiqColors.auroraTeal,
          LiqColors.auroraViolet,
        ];

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: LiqColors.bgDeep),
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            return CustomPaint(
              painter: _AuroraPainter(
                t: _ctrl.value,
                colors: palette,
                intensity: widget.intensity,
              ),
              size: Size.infinite,
            );
          },
        ),
        // Subtle vignette
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.4),
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.45),
                ],
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({
    required this.t,
    required this.colors,
    required this.intensity,
  });

  final double t;
  final List<Color> colors;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final angle = t * 2 * math.pi;

    for (var i = 0; i < colors.length; i++) {
      final phase = angle + i * (2 * math.pi / colors.length);
      final cx = w * (0.5 + 0.32 * math.cos(phase));
      final cy = h * (0.45 + 0.28 * math.sin(phase * 0.7 + i));
      final radius = math.max(w, h) * (0.55 + 0.1 * math.sin(phase * 1.3));

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            colors[i].withOpacity(0.55 * intensity),
            colors[i].withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.intensity != intensity;
}
