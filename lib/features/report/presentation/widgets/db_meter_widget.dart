import 'package:flutter/material.dart';
import '../../../../core/utils/db_classifier.dart';

/// Ripple-wave dB meter:
///  - 3 concentric rings expand from center while measuring
///  - Ring max-radius and color react to current dB level
///  - Smooth dB value interpolation between readings
class DbMeterWidget extends StatefulWidget {
  final double currentDb;
  final bool isMeasuring;

  const DbMeterWidget({
    super.key,
    required this.currentDb,
    this.isMeasuring = false,
  });

  @override
  State<DbMeterWidget> createState() => _DbMeterWidgetState();
}

class _DbMeterWidgetState extends State<DbMeterWidget>
    with TickerProviderStateMixin {
  // Ripple rings: repeating 0→1, 1600ms cycle
  late AnimationController _rippleController;

  // dB value smooth interpolation
  late AnimationController _dbController;
  late Animation<double> _dbAnim;

  @override
  void initState() {
    super.initState();

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _dbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _dbAnim = Tween<double>(
      begin: widget.currentDb,
      end: widget.currentDb,
    ).animate(CurvedAnimation(parent: _dbController, curve: Curves.easeOut));

    if (widget.isMeasuring) {
      _rippleController.repeat();
    }
  }

  @override
  void didUpdateWidget(DbMeterWidget old) {
    super.didUpdateWidget(old);

    // ── Ripple start / stop ──────────────────────────────
    if (widget.isMeasuring && !_rippleController.isAnimating) {
      _rippleController.repeat();
    } else if (!widget.isMeasuring && _rippleController.isAnimating) {
      _rippleController.stop();
      _rippleController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }

    // ── dB smooth interpolation ──────────────────────────
    if (old.currentDb != widget.currentDb) {
      final fromDb = _dbAnim.value;
      _dbAnim = Tween<double>(begin: fromDb, end: widget.currentDb).animate(
        CurvedAnimation(parent: _dbController, curve: Curves.easeOut),
      );
      _dbController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _dbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rippleController, _dbAnim]),
      builder: (context, _) {
        final animDb = _dbAnim.value;
        final color = DbClassifier.colorFromDb(animDb);
        final label = DbClassifier.labelFromDb(animDb);

        return SizedBox(
          width: 260,
          height: 260,
          child: CustomPaint(
            painter: _RipplePainter(
              progress: _rippleController.value,
              db: animDb,
              color: color,
              isMeasuring: widget.isMeasuring,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    animDb.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.w300,
                      color: widget.isMeasuring
                          ? color
                          : const Color(0xFFBDBDBD),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'dB',
                    style: TextStyle(
                      fontSize: 15,
                      color: widget.isMeasuring
                          ? color.withValues(alpha: 0.7)
                          : Colors.grey.shade400,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color:
                          (widget.isMeasuring ? color : Colors.grey.shade400)
                              .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.isMeasuring
                            ? color
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Ripple Painter
// 3 staggered rings expand from center → fade out
// ─────────────────────────────────────────────
class _RipplePainter extends CustomPainter {
  final double progress;
  final double db;
  final Color color;
  final bool isMeasuring;

  static const int _rings = 3;

  const _RipplePainter({
    required this.progress,
    required this.db,
    required this.color,
    required this.isMeasuring,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Max ripple radius: maps dB 30→120 to 78→165 px (1.5× original)
    final normalised = ((db - 30) / 90).clamp(0.0, 1.0);
    final maxRadius = 78.0 + normalised * 87.0;

    // Center dot — always visible
    final dotColor = isMeasuring ? color : const Color(0xFFBDBDBD);
    canvas.drawCircle(center, 5.5, Paint()..color = dotColor);

    if (!isMeasuring) return;

    // 3 rings with 1/3 phase offset each
    for (int i = 0; i < _rings; i++) {
      final phase = (progress + i / _rings) % 1.0;

      // Apply ease-out so rings decelerate as they expand
      final easedPhase = 1.0 - (1.0 - phase) * (1.0 - phase);

      final radius = maxRadius * easedPhase;
      final opacity = (1.0 - phase).clamp(0.0, 1.0);

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: opacity * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.progress != progress ||
      old.db != db ||
      old.color != color ||
      old.isMeasuring != isMeasuring;
}
