import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/level_service.dart';

void showBadgeDetailSheet(BuildContext context, List<BadgeInfo> badges) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BadgeDetailSheet(badges: badges),
  );
}

class BadgeDetailSheet extends StatelessWidget {
  final List<BadgeInfo> badges;
  const BadgeDetailSheet({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    final unlockedCount = badges.where((b) => b.unlocked).length;

    // Group by category (preserving enum order)
    final Map<BadgeCategory, List<BadgeInfo>> byCategory = {};
    for (final b in badges) {
      byCategory.putIfAbsent(b.category, () => []).add(b);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Text(
                      '뱃지 컬렉션',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.mintGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$unlockedCount / ${badges.length} 획득',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mintGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Overall progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: badges.isEmpty ? 0 : unlockedCount / badges.length,
                    color: AppColors.mintGreen,
                    backgroundColor: AppColors.mintGreen.withValues(alpha: 0.12),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Badges grouped by category
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  children: [
                    for (final category in BadgeCategory.values) ...[
                      if (byCategory[category] != null) ...[
                        _CategoryHeader(
                          category: category,
                          badges: byCategory[category]!,
                        ),
                        const SizedBox(height: 10),
                        ...byCategory[category]!.map((b) => _BadgeCard(badge: b)),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Category header row
// ──────────────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  final BadgeCategory category;
  final List<BadgeInfo> badges;
  const _CategoryHeader({required this.category, required this.badges});

  @override
  Widget build(BuildContext context) {
    final unlocked = badges.where((b) => b.unlocked).length;
    return Row(
      children: [
        Text(category.emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          category.label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$unlocked/${badges.length}',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Badge card
// ──────────────────────────────────────────────────────────────

class _BadgeCard extends StatelessWidget {
  final BadgeInfo badge;
  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: badge.unlocked ? Colors.white : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badge.unlocked
              ? AppColors.mintGreen.withValues(alpha: 0.25)
              : Colors.grey.shade200,
        ),
        boxShadow: badge.unlocked
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Emoji circle
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: badge.unlocked
                  ? AppColors.mintGreen.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              badge.unlocked ? badge.emoji : '🔒',
              style: const TextStyle(fontSize: 26),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: badge.unlocked
                        ? const Color(0xFF1A1A1A)
                        : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  badge.condition,
                  style: TextStyle(
                    fontSize: 13,
                    color: badge.unlocked
                        ? AppColors.textSecondary
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status + XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (badge.unlocked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.mintGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '획득',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '미획득',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                '+${badge.xpReward} XP',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: badge.unlocked
                      ? AppColors.mintGreen
                      : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
