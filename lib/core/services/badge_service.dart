import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/level_service.dart';

/// Handles all badge award logic:
///   - checkAndAward: evaluate stats-based badges (B01–B03, B05–B28),
///     insert newly earned rows to user_badges, award XP.
///   - awardInstantBadge: one-time event badges (B04, B29).
abstract class BadgeService {
  // ──────────────────────────────────────────────────────────
  // Stats-based batch check (called after report submit)
  // ──────────────────────────────────────────────────────────

  /// Compute which badges are newly earned, persist them, and award XP.
  /// Returns the list of newly earned BadgeInfo for popup display.
  static Future<List<BadgeInfo>> checkAndAward({
    required SupabaseClient client,
    required BadgeStats stats,
    required Set<String> earnedIds,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];

    // Evaluate all 30 badges
    final allBadges = LevelService.calcBadges(stats, earnedIds);

    // Newly earned = eligible NOW and NOT already in DB
    final newBadges = allBadges
        .where((b) => b.unlocked && !earnedIds.contains(b.id))
        .toList();

    if (newBadges.isEmpty) return [];

    // Persist to user_badges
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await client.from('user_badges').insert(
        newBadges
            .map((b) => {'user_id': userId, 'badge_id': b.id, 'earned_at': now})
            .toList(),
      );
    } catch (_) {
      return []; // DB insert failed — don't show popup for badges not persisted
    }

    // Award XP (sum of all new badge rewards)
    final totalXp = newBadges.fold(0, (sum, b) => sum + b.xpReward);
    if (totalXp > 0) {
      try {
        await client.rpc('award_xp', params: {
          'p_user_id': userId,
          'p_xp': totalXp,
        });
      } catch (e) {
        debugPrint('[BadgeService] XP award failed: $e');
      }
    }

    return newBadges;
  }

  // ──────────────────────────────────────────────────────────
  // Instant-award badges triggered by specific UI events
  // ──────────────────────────────────────────────────────────

  /// Award a single badge (B04, B29) if not already earned.
  /// Returns the BadgeInfo if newly awarded, null if already earned.
  static Future<BadgeInfo?> awardInstantBadge({
    required SupabaseClient client,
    required String badgeId,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    // Check if already earned
    final existing = await client
        .from('user_badges')
        .select('badge_id')
        .eq('user_id', userId)
        .eq('badge_id', badgeId)
        .maybeSingle();

    if (existing != null) return null; // already earned

    // Find badge definition
    final allBadges = LevelService.calcBadges(BadgeStats.empty(), {badgeId});
    final badge = allBadges.where((b) => b.id == badgeId).firstOrNull;
    if (badge == null) return null;

    // Persist
    try {
      await client.from('user_badges').insert({
        'user_id': userId,
        'badge_id': badgeId,
      });
    } catch (_) {
      return null;
    }

    // Award XP
    if (badge.xpReward > 0) {
      try {
        await client.rpc('award_xp', params: {
          'p_user_id': userId,
          'p_xp': badge.xpReward,
        });
      } catch (e) {
        debugPrint('[BadgeService] instant XP award failed: $e');
      }
    }

    return badge;
  }

  // ──────────────────────────────────────────────────────────
  // Read-only helpers
  // ──────────────────────────────────────────────────────────

  /// Fetch the set of badge IDs already earned by the current user.
  static Future<Set<String>> getEarnedBadgeIds(SupabaseClient client) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return {};
    try {
      final res = await client
          .from('user_badges')
          .select('badge_id')
          .eq('user_id', userId);
      return (res as List)
          .cast<Map<String, dynamic>>()
          .map((r) => r['badge_id'] as String)
          .toSet();
    } catch (_) {
      return {};
    }
  }
}
