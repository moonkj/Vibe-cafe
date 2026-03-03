import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class FlowingWavePainter extends CustomPainter {
  final double animation;
  final bool isDark;

  const FlowingWavePainter({required this.animation, this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cy = h * 0.5;

    _paintRibbon(canvas, w, h, cy);
    _paintGlowParticles(canvas, w, h, cy);
    _paintMusicNotes(canvas, w, h, cy);
  }

  void _paintRibbon(Canvas canvas, double w, double h, double cy) {
    final phase = animation * 2 * math.pi;
    final alphaBase = isDark ? 1.0 : 0.85;

    const lineCount = 16;
    final ribbonHalfWidth = h * 0.25;

    final heroShader = LinearGradient(
      colors: [
        AppColors.mintGreen.withValues(alpha: 0.85 * alphaBase),
        AppColors.skyBlue.withValues(alpha: 0.70 * alphaBase),
      ],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    for (int i = 0; i < lineCount; i++) {
      final t = (i - (lineCount - 1) / 2) / ((lineCount - 1) / 2);
      final absT = t.abs();
      final ribbonOffset = t * ribbonHalfWidth;
      final opacity = (0.08 + 0.62 * (1.0 - absT)) * alphaBase;
      final sw = 0.6 + 1.6 * (1.0 - absT);
      final linePhase = phase + i * 0.06;

      final path = Path();
      const steps = 200;

      for (int j = 0; j <= steps; j++) {
        final nx = j / steps;
        final x = w * nx;

        final wave1 = math.sin(nx * 0.7 * 2 * math.pi + linePhase);
        final wave2 = math.sin(nx * 1.3 * 2 * math.pi + linePhase * 0.8) * 0.25;
        final wave = wave1 + wave2;

        final mainAmp = h * 0.28;

        final spread = wave.abs().clamp(0.2, 1.0);
        final dynamicOffset = ribbonOffset * (0.4 + 0.6 * spread);

        final y = cy + mainAmp * wave + dynamicOffset;
        j == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (absT < 0.25) {
        paint.shader = heroShader;
      } else {
        final colorT = (t + 1) / 2;
        paint.color =
            Color.lerp(AppColors.mintGreen, AppColors.skyBlue, colorT)!
                .withValues(alpha: opacity);
      }

      canvas.drawPath(path, paint);
    }
  }

  void _paintGlowParticles(Canvas canvas, double w, double h, double cy) {
    final rng = math.Random(42);
    final alphaBoost = isDark ? 1.0 : 0.85;

    const count = 14;
    for (int i = 0; i < count; i++) {
      final baseX = rng.nextDouble() * w;
      final baseY = cy + (rng.nextDouble() - 0.5) * h * 0.8;

      final p = (animation * 0.5 + i / count) % 1.0;
      final dx = baseX + math.sin(p * 2 * math.pi + i) * 8;
      final dy = baseY - p * 14;

      final opacity =
          (math.sin(p * math.pi) * 0.5 * alphaBoost).clamp(0.05, 0.5);
      final radius = 2.0 + rng.nextDouble() * 2.5;

      final glowPaint = Paint()
        ..color = AppColors.mintGreen.withValues(alpha: opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(dx, dy), radius * 2.5, glowPaint);

      final color = i.isEven
          ? AppColors.mintGreen.withValues(alpha: opacity)
          : AppColors.skyBlue.withValues(alpha: opacity * 0.8);
      canvas.drawCircle(Offset(dx, dy), radius, Paint()..color = color);
    }
  }

  void _paintMusicNotes(Canvas canvas, double w, double h, double cy) {
    final rng = math.Random(77);
    const notes = ['♪', '♫', '♪', '♫', '♪', '♪'];
    final alphaBoost = isDark ? 1.0 : 0.85;

    for (int i = 0; i < notes.length; i++) {
      final baseX = w * 0.08 + rng.nextDouble() * w * 0.84;
      final baseY = cy + (rng.nextDouble() - 0.5) * h * 0.7;

      final p = (animation * 0.4 + i / notes.length) % 1.0;
      final dx = baseX + math.sin(p * 2 * math.pi + i * 1.2) * 12;
      final dy = baseY - p * 24;

      final opacity =
          (math.sin(p * math.pi) * 0.42 * alphaBoost).clamp(0.0, 0.42);
      if (opacity < 0.04) continue;

      final fontSize = 14.0 + rng.nextDouble() * 6.0;

      final tp = TextPainter(
        text: TextSpan(
          text: notes[i],
          style: TextStyle(
            fontSize: fontSize,
            color: AppColors.mintGreen.withValues(alpha: opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(FlowingWavePainter old) =>
      old.animation != animation || old.isDark != isDark;
}
