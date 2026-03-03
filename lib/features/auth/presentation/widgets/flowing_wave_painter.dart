import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Continuously flowing sine wave animation for the onboarding screen.
///
/// Three overlapping waves with different frequencies and phase speeds
/// create a rich audio-visualizer feel. The primary wave uses the brand
/// gradient; secondary and tertiary waves are tinted flat colors.
///
/// [animation] — repeating 0.0–1.0 value (drives phase offset)
/// [isDark]    — adapts opacity/color for light vs dark background
class FlowingWavePainter extends CustomPainter {
  final double animation;
  final bool isDark;

  const FlowingWavePainter({required this.animation, this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cy = h / 2;

    // Wave layer definitions:
    //   (amplitude as fraction of height, frequency in cycles, phase speed multiplier)
    // speedMult > 0  → flows rightward
    // speedMult < 0  → flows leftward (subtle counter-motion)
    const layers = [
      (ampRatio: 0.30, freq: 1.5,  speed: 1.0 ),  // primary — gradient
      (ampRatio: 0.20, freq: 2.6,  speed: -0.65),  // secondary — skyBlue
      (ampRatio: 0.12, freq: 3.9,  speed: 1.35 ),  // tertiary — faint
    ];

    final gradientShader = LinearGradient(
      colors: [
        AppColors.mintGreen.withValues(alpha: isDark ? 0.92 : 0.80),
        AppColors.skyBlue.withValues(alpha: isDark ? 0.92 : 0.80),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    for (int i = 0; i < layers.length; i++) {
      final layer = layers[i];
      final amp   = h * layer.ampRatio;
      final phase = animation * 2 * math.pi * layer.speed;

      final path = Path();
      const steps = 240; // enough resolution for a smooth curve
      for (int j = 0; j <= steps; j++) {
        final x = w * j / steps;
        final y = cy + amp * math.sin(layer.freq * 2 * math.pi * j / steps + phase);
        j == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }

      final Paint paint;
      if (i == 0) {
        // Primary wave: brand gradient
        paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..shader = gradientShader;
      } else {
        // Secondary / tertiary: flat tint
        final t = i / (layers.length - 1);
        final color = Color.lerp(AppColors.mintGreen, AppColors.skyBlue, t)!
            .withValues(alpha: (i == 1 ? 0.50 : 0.25) * (isDark ? 1.0 : 0.85));
        paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == 1 ? 1.6 : 1.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = color;
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(FlowingWavePainter old) =>
      old.animation != animation || old.isDark != isDark;
}
