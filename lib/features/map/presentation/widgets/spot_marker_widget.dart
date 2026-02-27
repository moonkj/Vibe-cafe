import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/db_classifier.dart';
import '../../domain/spot_model.dart';

/// Circular spot marker showing dB-based color and trust_score border thickness.
/// Used for custom Google Maps marker bitmaps via [RepaintBoundary].
class SpotMarkerWidget extends StatelessWidget {
  final SpotModel spot;
  final bool isReduced;

  const SpotMarkerWidget({
    super.key,
    required this.spot,
    this.isReduced = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = isReduced ? 24.0 : 32.0;
    final color = DbClassifier.colorFromDb(spot.averageDb);
    final borderWidth = isReduced ? 1.5 : spot.markerBorderWidth;

    return Opacity(
      opacity: spot.markerOpacity,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: Colors.white, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isReduced
            ? null
            : Center(
                child: Text(
                  spot.averageDb.toStringAsFixed(0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Bottom sheet card shown when a spot marker is tapped.
class SpotInfoCard extends StatelessWidget {
  final SpotModel spot;
  final VoidCallback onReport;

  const SpotInfoCard({super.key, required this.spot, required this.onReport});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spot name + dB badge
          Row(
            children: [
              Expanded(
                child: Text(
                  spot.name,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: DbClassifier.colorFromDb(spot.averageDb)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${spot.averageDb.toStringAsFixed(1)} dB',
                  style: TextStyle(
                    color: DbClassifier.colorFromDb(spot.averageDb),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Label + sticker
          Row(
            children: [
              Text(
                DbClassifier.labelFromDb(spot.averageDb),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (spot.representativeSticker != null) ...[
                const SizedBox(width: 8),
                Text(
                  '${spot.representativeSticker!.emoji} ${spot.representativeSticker!.label}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Social proof
          _SocialProofRow(spot: spot),
          const SizedBox(height: 16),
          // Report button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onReport,
              child: const Text('지금 소음 측정하기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialProofRow extends StatelessWidget {
  final SpotModel spot;
  const _SocialProofRow({required this.spot});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(
          label: '최근 24시간 ${spot.recent24hCount}건',
          icon: Icons.bar_chart_rounded,
        ),
        const SizedBox(width: 8),
        _Chip(
          label: '리포트 ${spot.reportCount}회',
          icon: Icons.check_circle_outline_rounded,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Chip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgMap,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
