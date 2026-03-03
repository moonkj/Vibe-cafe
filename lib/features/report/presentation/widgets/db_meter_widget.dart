import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/db_classifier.dart';

/// Ripple-wave dB meter:
///  - Charcoal filled circle (radius 100) at center, always visible
///  - 5 concentric rings expand from center while measuring
///  - Ring radius and color react to current dB level
///  - Rolling AnimatedSwitcher for dB number changes
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
        final inactiveColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3);

        return SizedBox(
          width: 280,
          height: 280,
          child: CustomPaint(
            painter: _RipplePainter(
              progress: _rippleController.value,
              db: animDb,
              color: color,
              isMeasuring: widget.isMeasuring,
              inactiveColor: inactiveColor,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Rolling number animation
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) => SlideTransition(
                      position: Tween(
                        begin: const Offset(0, -0.3),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Text(
                      key: ValueKey(animDb.toStringAsFixed(0)),
                      animDb.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w700,
                        color: widget.isMeasuring
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.55),
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'dB',
                    style: TextStyle(
                      fontSize: 15,
                      color: widget.isMeasuring
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.35),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: widget.isMeasuring
                          ? color.withValues(alpha: 0.15)
                          : inactiveColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.isMeasuring ? color : inactiveColor,
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
// Charcoal center circle + 5 staggered rings expand from center → fade out
// ─────────────────────────────────────────────
class _RipplePainter extends CustomPainter {
  final double progress;
  final double db;
  final Color color;
  final bool isMeasuring;
  final Color inactiveColor;

  static const int _rings = 5;
  static const double _centerRadius = 100.0;

  const _RipplePainter({
    required this.progress,
    required this.db,
    required this.color,
    required this.isMeasuring,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw charcoal center circle (always visible)
    canvas.drawCircle(
      center,
      _centerRadius,
      Paint()..color = const Color(0xFF252525),
    );

    // Max ripple radius: maps dB 30→120 to 105→200 px
    final normalised = ((db - 30) / 90).clamp(0.0, 1.0);
    final maxRadius = 105.0 + normalised * 95.0;

    // Center dot
    final dotColor = isMeasuring ? color : inactiveColor.withValues(alpha: 0.6);
    canvas.drawCircle(center, 5.5, Paint()..color = dotColor);

    if (!isMeasuring) return;

    // 5 rings with 1/5 phase offset each, gradient colors
    final ringColors = _buildRingColors();

    for (int i = 0; i < _rings; i++) {
      final phase = (progress + i / _rings) % 1.0;

      // Apply ease-out so rings decelerate as they expand
      final easedPhase = 1.0 - (1.0 - phase) * (1.0 - phase);

      final radius = _centerRadius + (maxRadius - _centerRadius) * easedPhase;
      final opacity = (1.0 - phase).clamp(0.0, 1.0);

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = ringColors[i].withValues(alpha: opacity * 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  /// Build 5 ring colors sweeping from mintGreen → dbColor based on dB
  List<Color> _buildRingColors() {
    // At low dB: all mintGreen. At high dB: blend toward the dB color (warm).
    return List.generate(_rings, (i) {
      final t = i / (_rings - 1); // 0.0 → 1.0
      return Color.lerp(AppColors.mintGreen, color, t * 0.8)!;
    });
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.progress != progress ||
      old.db != db ||
      old.color != color ||
      old.isMeasuring != isMeasuring ||
      old.inactiveColor != inactiveColor;
}
