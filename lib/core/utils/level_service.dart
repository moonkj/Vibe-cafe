import '../constants/app_strings.dart';

class UserLevel {
  final int level;       // 1~10
  final String name;     // 바이브 비기너 등
  final String icon;     // 레벨 아이콘 (이모지)
  final int currentXp;   // 누적 XP
  final int nextTarget;  // 다음 레벨 누적 XP 목표 (-1 if max)
  final double progress; // 0.0~1.0 (구간 내 진행률)

  const UserLevel({
    required this.level,
    required this.name,
    required this.icon,
    required this.currentXp,
    required this.nextTarget,
    required this.progress,
  });

  bool get isMax => level >= 10;
}

class BadgeInfo {
  final String emoji;
  final String label;
  final String condition; // 획득 조건 설명
  final bool unlocked;

  const BadgeInfo({
    required this.emoji,
    required this.label,
    required this.condition,
    required this.unlocked,
  });
}

abstract class LevelService {
  /// Cumulative XP thresholds for Lv1~Lv10
  static const _xpThresholds = [0, 30, 80, 160, 280, 450, 700, 1050, 1500, 2100];

  /// XP gained per action
  static const int xpPerReport = 10; // 1일 1회 제한
  static const int xpNewCafe = 5;    // 처음 가본 카페 보너스

  static UserLevel calcLevel(int totalXp) {
    int lv = 1;
    for (int i = _xpThresholds.length - 1; i >= 0; i--) {
      if (totalXp >= _xpThresholds[i]) {
        lv = i + 1;
        break;
      }
    }
    lv = lv.clamp(1, 10);

    final int nextTarget;
    final double progress;

    if (lv >= 10) {
      nextTarget = -1;
      progress = 1.0;
    } else {
      final levelStart = _xpThresholds[lv - 1];
      final levelEnd = _xpThresholds[lv];
      final gap = levelEnd - levelStart;
      nextTarget = levelEnd;
      progress = ((totalXp - levelStart) / gap).clamp(0.0, 1.0);
    }

    return UserLevel(
      level: lv,
      name: AppStrings.levelNames[lv - 1],
      icon: AppStrings.levelIcons[lv - 1],
      currentXp: totalXp,
      nextTarget: nextTarget,
      progress: progress,
    );
  }

  static List<BadgeInfo> calcBadges({
    required int totalReports,
    required int totalCafes,
    required bool hasQuietCafe,
  }) {
    return [
      BadgeInfo(
        emoji: '🔰',
        label: '데시벨 입문자',
        condition: '첫 번째 바이브 측정 완료',
        unlocked: totalReports >= 1,
      ),
      BadgeInfo(
        emoji: '🤫',
        label: '조용한 발견자',
        condition: '평균 50dB 미만 카페 발견',
        unlocked: hasQuietCafe,
      ),
      BadgeInfo(
        emoji: '📊',
        label: '측정 5회',
        condition: '누적 5회 이상 측정',
        unlocked: totalReports >= 5,
      ),
      BadgeInfo(
        emoji: '🧭',
        label: '카페 탐험가',
        condition: '2곳 이상 카페 방문',
        unlocked: totalCafes >= 2,
      ),
    ];
  }
}
