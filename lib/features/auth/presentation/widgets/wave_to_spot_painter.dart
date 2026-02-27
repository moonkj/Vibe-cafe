import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Paints the "Frequency of Calm" brand motif as a drawing animation.
///
/// A small white dot traces left → jagged wave → smooth arc → Spot circle.
/// [progress] 0.0–1.0: the dot moves along the path, drawing a trail behind it.
class WaveToSpotPainter extends CustomPainter {
  final double progress;

  WaveToSpotPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final midY = h / 2;

    // Layout — compact centred composition matching icon proportions
    final waveStartX = w * 0.22;
    final spotX = w * 0.76;
    final spotY = midY + h * 0.02;

    // ── Build the complete path ──────────────────────────────────
    final path = Path()..moveTo(waveStartX, midY);

    // EKG heartbeat cluster — concentrated spikes matching the icon
    // negative amp = UP on screen, positive = DOWN
    final amp = h * 0.42;
    final segments = [
      [0.240,  0.00],  // flat lead-in
      [0.258,  0.18],  // slight dip down
      [0.272, -0.32],  // small bump up
      [0.286,  0.52],  // dip down
      [0.297, -1.00],  // ── BIG spike UP (tallest, like icon's main peak)
      [0.312,  0.88],  // ── deep dip DOWN
      [0.326, -0.82],  // second major spike UP
      [0.342,  0.62],  // down (moderate)
      [0.357, -0.45],  // spike UP (shrinking)
      [0.372,  0.28],  // down (smaller)
      [0.388, -0.15],  // slight up
      [0.406,  0.06],  // settling
      [0.440,  0.00],  // back to flat
      [0.480,  0.00],  // flat
      [0.520,  0.00],  // wave end → arc start
    ];
    for (final seg in segments) {
      path.lineTo(seg[0] * w, midY + seg[1] * amp);
    }

    // Smooth arc with pronounced upward curvature (control point high above)
    path.quadraticBezierTo(
      w * 0.63, midY - h * 0.52,
      spotX, spotY,
    );

    // ── PathMetric-based drawing animation ───────────────────────
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final totalLen = metric.length;
    final drawn = (totalLen * progress).clamp(0.0, totalLen);

    // Gradient stroke for the trail
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        colors: [AppColors.mintGreen, Colors.white],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(waveStartX, 0, spotX - waveStartX, h));

    canvas.drawPath(metric.extractPath(0, drawn), strokePaint);

    // Leading dot — rides at the tip of the drawn trail
    if (progress > 0.01 && progress < 0.96) {
      final tangent = metric.getTangentForOffset(drawn);
      if (tangent != null) {
        canvas.drawCircle(
          tangent.position,
          3.5,
          Paint()..color = Colors.white,
        );
      }
    }

    // Spot circle blooms as the dot arrives at the end
    if (progress > 0.90) {
      final t = ((progress - 0.90) / 0.10).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(spotX, spotY),
        12.0 * t,
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.white.withValues(alpha: t),
      );
    }
  }

  @override
  bool shouldRepaint(WaveToSpotPainter old) => old.progress != progress;
}
