import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/db_classifier.dart';

class DbMeterWidget extends StatelessWidget {
  final double currentDb;
  final bool isStabilizing;

  const DbMeterWidget({
    super.key,
    required this.currentDb,
    this.isStabilizing = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = DbClassifier.colorFromDb(currentDb);
    final label = DbClassifier.labelFromDb(currentDb);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Large dB number
        ShaderMask(
          shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
          child: Text(
            currentDb.toStringAsFixed(1),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w200,
                ),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 2000.ms, color: color.withValues(alpha: 0.3)),
        Text(
          'dB',
          style: TextStyle(
            fontSize: 20,
            color: color,
            fontWeight: FontWeight.w400,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        // Wave bar visualizer
        _WaveBar(db: currentDb, color: color),
        if (isStabilizing) ...[
          const SizedBox(height: 16),
          Text(
            '3초 안정화 중...',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 600.ms).then().fadeOut(duration: 600.ms),
        ],
      ],
    );
  }
}

class _WaveBar extends StatelessWidget {
  final double db;
  final Color color;
  const _WaveBar({required this.db, required this.color});

  @override
  Widget build(BuildContext context) {
    final normalised = ((db - 20) / 80).clamp(0.0, 1.0);
    return SizedBox(
      height: 48,
      child: CustomPaint(
        painter: _WaveBarPainter(normalised: normalised, color: color),
        size: const Size(double.infinity, 48),
      ),
    );
  }
}

class _WaveBarPainter extends CustomPainter {
  final double normalised;
  final Color color;
  _WaveBarPainter({required this.normalised, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    const barCount = 32;
    final barWidth = size.width / barCount * 0.6;
    final gap = size.width / barCount * 0.4;

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + gap);
      final heightFactor =
          normalised * (0.3 + 0.7 * math.sin(i * 0.4).abs());
      final barHeight = size.height * heightFactor;
      final top = (size.height - barHeight) / 2;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        const Radius.circular(2),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveBarPainter old) =>
      old.normalised != normalised || old.color != color;
}
