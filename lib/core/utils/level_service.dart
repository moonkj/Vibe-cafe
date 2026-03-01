import '../constants/app_strings.dart';

class UserLevel {
  final int level;      // 1~5
  final String name;    // 카페 탐험가 등
  final int current;    // 현재 보고 수
  final int nextTarget; // 다음 레벨 목표 (5 레벨이면 -1)
  final double progress; // 0.0~1.0

  const UserLevel({
    required this.level,
    required this.name,
    required this.current,
    required this.nextTarget,
    required this.progress,
  });

  bool get isMax => level >= 5;
}

class BadgeInfo {
  final String emoji;
  final String label;
  final bool unlocked;

  const BadgeInfo({required this.emoji, required this.label, required this.unlocked});
}

abstract class LevelService {
  static const _thresholds = [0, 5, 10, 20, 50]; // levels 1~5 시작 보고 수

  static UserLevel calcLevel(int totalReports) {
    int lv = 1;
    for (int i = _thresholds.length - 1; i >= 0; i--) {
      if (totalReports >= _thresholds[i]) {
        lv = i + 1;
        break;
      }
    }
    lv = lv.clamp(1, 5);

    final current = totalReports - _thresholds[lv - 1];
    final int nextTarget;
    final double progress;

    if (lv >= 5) {
      nextTarget = -1;
      progress = 1.0;
    } else {
      final gap = _thresholds[lv] - _thresholds[lv - 1];
      nextTarget = _thresholds[lv];
      progress = (current / gap).clamp(0.0, 1.0);
    }

    return UserLevel(
      level: lv,
      name: AppStrings.levelNames[lv - 1],
      current: totalReports,
      nextTarget: nextTarget,
      progress: progress,
    );
  }

  static int calcPoints(int totalReports, int totalCafes) {
    return totalReports * 50 + totalCafes * 70;
  }

  static List<BadgeInfo> calcBadges({
    required int totalReports,
    required int totalCafes,
    required bool hasQuietCafe, // avg_db < 50인 카페 방문 기록 있음
  }) {
    return [
      BadgeInfo(emoji: '🎤', label: '첫 측정',     unlocked: totalReports >= 1),
      BadgeInfo(emoji: '📻', label: '조용한 발견자', unlocked: hasQuietCafe),
      BadgeInfo(emoji: '⭐', label: '측정 5회',     unlocked: totalReports >= 5),
      BadgeInfo(emoji: '🗺️', label: '카페 탐험가',  unlocked: totalCafes >= 2),
    ];
  }
}
