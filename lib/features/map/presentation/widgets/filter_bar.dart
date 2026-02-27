import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/spot_model.dart';

class FilterBar extends StatelessWidget {
  final StickerType? activeFilter;
  final ValueChanged<StickerType?> onFilterChanged;

  const FilterBar({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'STUDY',
            emoji: '📚',
            isActive: activeFilter == StickerType.study,
            color: AppColors.stickerStudy,
            onTap: () => onFilterChanged(
              activeFilter == StickerType.study ? null : StickerType.study,
            ),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'MEETING',
            emoji: '📹',
            isActive: activeFilter == StickerType.meeting,
            color: AppColors.stickerMeeting,
            onTap: () => onFilterChanged(
              activeFilter == StickerType.meeting ? null : StickerType.meeting,
            ),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'RELAX',
            emoji: '🌿',
            isActive: activeFilter == StickerType.relax,
            color: AppColors.stickerRelax,
            onTap: () => onFilterChanged(
              activeFilter == StickerType.relax ? null : StickerType.relax,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.emoji,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActive ? color : AppColors.divider,
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
