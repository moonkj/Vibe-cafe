import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/level_service.dart';

/// Show the badge-earned congratulation bottom sheet.
/// Automatically dismisses after [autoDismiss] duration.
Future<void> showBadgeEarnedPopup(
  BuildContext context,
  BadgeInfo badge, {
  Duration autoDismiss = const Duration(seconds: 3),
}) async {
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (_) => _BadgeEarnedSheet(badge: badge, autoDismiss: autoDismiss),
  );
}

class _BadgeEarnedSheet extends StatefulWidget {
  final BadgeInfo badge;
  final Duration autoDismiss;
  const _BadgeEarnedSheet({required this.badge, required this.autoDismiss});

  @override
  State<_BadgeEarnedSheet> createState() => _BadgeEarnedSheetState();
}

class _BadgeEarnedSheetState extends State<_BadgeEarnedSheet> {
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.autoDismiss, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        margin: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.mintGreen.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sparkle badge emoji
            Text(
              widget.badge.emoji,
              style: const TextStyle(fontSize: 64),
            )
                .animate()
                .scale(
                  begin: const Offset(0.4, 0.4),
                  end: const Offset(1.0, 1.0),
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                ),

            const SizedBox(height: 12),

            // "뱃지 획득!" label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.mintGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '🎊 뱃지 획득!',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 14),

            // Badge name
            Text(
              widget.badge.label,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 6),

            // Condition description
            Text(
              widget.badge.condition,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
              ),
              textAlign: TextAlign.center,
            )
                .animate(delay: 400.ms)
                .fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            // XP reward chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.mintGreen.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.mintGreen.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars_rounded,
                      size: 18, color: AppColors.mintGreen),
                  const SizedBox(width: 6),
                  Text(
                    '+${widget.badge.xpReward} XP',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mintGreen,
                    ),
                  ),
                ],
              ),
            )
                .animate(delay: 500.ms)
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),

            const SizedBox(height: 8),

            Text(
              '탭하여 닫기',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35)),
            )
                .animate(delay: 2200.ms)
                .fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
