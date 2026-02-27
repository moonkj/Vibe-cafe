import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../map/domain/spot_model.dart';

class StickerCardGrid extends StatelessWidget {
  final double measuredDb;
  final ValueChanged<StickerType> onSelected;

  const StickerCardGrid({
    super.key,
    required this.measuredDb,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '측정 완료: ${measuredDb.toStringAsFixed(1)} dB',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.mintGreen,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                '이 공간을 한마디로 표현하면?',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            _StickerCard(
              sticker: StickerType.study,
              color: AppColors.stickerStudy,
              onTap: () => onSelected(StickerType.study),
              delay: 0,
            ),
            const SizedBox(width: 10),
            _StickerCard(
              sticker: StickerType.meeting,
              color: AppColors.stickerMeeting,
              onTap: () => onSelected(StickerType.meeting),
              delay: 100,
            ),
            const SizedBox(width: 10),
            _StickerCard(
              sticker: StickerType.relax,
              color: AppColors.stickerRelax,
              onTap: () => onSelected(StickerType.relax),
              delay: 200,
            ),
          ],
        ),
      ],
    );
  }
}

class _StickerCard extends StatelessWidget {
  final StickerType sticker;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  const _StickerCard({
    required this.sticker,
    required this.color,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(sticker.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                sticker.key,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sticker.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1));
  }
}
