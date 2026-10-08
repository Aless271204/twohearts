import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

/// Central service for all game-related Supabase operations
class GameService {
  static GameService? _instance;
  static GameService get instance => _instance ??= GameService._();
  GameService._();

  SupabaseClient get _db => SupabaseService.instance.client;
  String? get _uid => SupabaseService.instance.currentUser?.id;
  bool _retryingRunner = false;

  Future<Map<String, dynamic>> _runnerRequest(
    Map<String, dynamic> payload,
  ) async {
    final response = await _db.functions.invoke('forest-runner', body: payload);
    final data = Map<String, dynamic>.from(response.data as Map);
    if (response.status != 200 || data['error'] != null)
      throw StateError('Runner request failed');
    return data;
  }

  Future<Map<String, dynamic>> startRunnerSession() async {
    if (_uid == null) return {'guest': true};
    return _runnerRequest({'action': 'start'});
  }

  Future<Map<String, dynamic>> finishRunnerSession(
    Map<String, dynamic> payload,
  ) async {
    final uid = _uid;
    if (uid == null) throw StateError('Sign in to save your run');
    final sessionId = payload['session_id'];
    if (sessionId is! String || payload['frames'] is! List)
      throw const FormatException('Invalid runner result');
    final prefs = await SharedPreferences.getInstance();
    final key = 'runner_pending_${uid}_$sessionId';
    final request = {'action': 'finish', ...payload};
    await prefs.setString(key, jsonEncode(request));
    final result = await _runnerRequest(request);
    await prefs.remove(key);
    return result;
  }

  Future<void> retryPendingRunnerRewards() async {
    final uid = _uid;
    if (uid == null || _retryingRunner) return;
    _retryingRunner = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key
          in prefs
              .getKeys()
              .where((key) => key.startsWith('runner_pending_${uid}_'))
              .take(5)) {
        try {
          final request =
              jsonDecode(prefs.getString(key)!) as Map<String, dynamic>;
          await _runnerRequest(request);
          await prefs.remove(key);
        } catch (_) {
          /* Retry the same idempotent session on the next visit. */
        }
      }
    } finally {
      _retryingRunner = false;
    }
  }

  // ─── GAME STATS ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getStats() async {
    final uid = _uid;
    if (uid == null) return _defaultStats();
    try {
      final row = await _db
          .from('game_stats')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      if (row == null) {
        await _db.rpc('inventory_snapshot');
        return _defaultStats();
      }
      return row;
    } catch (e) {
      debugPrint('getStats error: $e');
      return _defaultStats();
    }
  }

  Map<String, dynamic> _defaultStats() => {
    'love_coins': 0,
    'xp': 0,
    'level': 1,
    'total_games_played': 0,
    'total_coins_earned': 0,
  };

  // Rewards and records are written only by validated server functions.

  Future<Map<String, dynamic>?> getRecord(String gameId) async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      return await _db
          .from('game_records')
          .select()
          .eq('user_id', uid)
          .eq('game_id', gameId)
          .maybeSingle();
    } catch (e) {
      return null;
    }
  }

  int xpForNextLevel(int level) {
    switch (level) {
      case 1:
        return 200;
      case 2:
        return 500;
      case 3:
        return 1000;
      case 4:
        return 2000;
      default:
        return 9999;
    }
  }

  String levelName(int level) {
    switch (level) {
      case 1:
        return 'Enamorados';
      case 2:
        return 'Pareja';
      case 3:
        return 'Cómplices';
      case 4:
        return 'Aventureros';
      default:
        return 'Inseparables';
    }
  }

  // ─── DAILY CHALLENGES ────────────────────────────────────────────────────

  static const List<Map<String, dynamic>> _challengeTemplates = [
    {'key': 'play_1', 'label': 'Juega 1 partida', 'coins': 10},
    {'key': 'play_3', 'label': 'Juega 3 partidas', 'coins': 20},
    {'key': 'beat_record', 'label': 'Supera tu récord', 'coins': 25},
    {'key': 'play_together', 'label': 'Juega con tu pareja', 'coins': 30},
    {
      'key': 'buy_item',
      'label': 'Compra o desbloquea un accesorio',
      'coins': 10,
    },
  ];

  Future<List<Map<String, dynamic>>> getDailyChallenges() async {
    final uid = _uid;
    if (uid == null) return [];
    final today = DateTime.now().toIso8601String().split('T').first;
    try {
      // Ensure today's challenges exist
      for (final t in _challengeTemplates) {
        await _db
            .from('daily_challenges')
            .upsert(
              {
                'user_id': uid,
                'challenge_date': today,
                'challenge_key': t['key'],
                'challenge_label': t['label'],
                'reward_coins': t['coins'],
                'completed': false,
              },
              onConflict: 'user_id,challenge_date,challenge_key',
              ignoreDuplicates: true,
            );
      }

      final rows = await _db
          .from('daily_challenges')
          .select()
          .eq('user_id', uid)
          .eq('challenge_date', today)
          .order('reward_coins');
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      debugPrint('getDailyChallenges error: $e');
      return [];
    }
  }

  Future<void> completeChallenge(String challengeKey) async {
    final uid = _uid;
    if (uid == null) return;
    final today = DateTime.now().toIso8601String().split('T').first;
    try {
      final row = await _db
          .from('daily_challenges')
          .select()
          .eq('user_id', uid)
          .eq('challenge_date', today)
          .eq('challenge_key', challengeKey)
          .maybeSingle();

      if (row == null || row['completed'] == true) return;

      await _db
          .from('daily_challenges')
          .update({
            'completed': true,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', uid)
          .eq('challenge_date', today)
          .eq('challenge_key', challengeKey);

      // Award coins
      final coins = row['reward_coins'] as int? ?? 10;
      await _addCoins(coins);
    } catch (e) {
      debugPrint('completeChallenge error: $e');
    }
  }

  Future<void> _addCoins(int coins) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final current = await getStats();
      await _db
          .from('game_stats')
          .update({
            'love_coins': (current['love_coins'] as int? ?? 0) + coins,
            'total_coins_earned':
                (current['total_coins_earned'] as int? ?? 0) + coins,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', uid);
    } catch (e) {
      debugPrint('_addCoins error: $e');
    }
  }

  // ─── SHOP ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getShopItems() async {
    try {
      final rows = await _db.from('shop_items').select().order('sort_order');
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      debugPrint('getShopItems error: $e');
      return [];
    }
  }

  Future<List<String>> getOwnedItemKeys() async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final rows = await _db
          .from('owned_items')
          .select('item_key')
          .eq('user_id', uid);
      return List<String>.from(rows.map((r) => r['item_key'] as String));
    } catch (e) {
      return [];
    }
  }

  Future<bool> purchaseItem(String itemKey, int coinCost) async {
    try {
      await _db.rpc('inventory_purchase', params: {'p_item_key': itemKey});
      return true;
    } catch (e) {
      debugPrint('purchaseItem error: $e');
      return false;
    }
  }

  // ─── COUPLE STATS ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCoupleStats() async {
    final uid = _uid;
    if (uid == null) return {};
    try {
      final row = await _db
          .from('couple_game_stats')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      return row ?? {};
    } catch (e) {
      return {};
    }
  }

  Future<void> recordCoupleGame(int score) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final profile = await SupabaseService.instance.getMyProfile();
      final partnerId = profile?['partner_id'] as String?;
      final today = DateTime.now().toIso8601String().split('T').first;

      final existing = await _db
          .from('couple_game_stats')
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      if (existing == null) {
        await _db.from('couple_game_stats').insert({
          'user_id': uid,
          'partner_id': partnerId,
          'games_together': 1,
          'coins_together': 0,
          'best_couple_score': score,
          'streak_days': 1,
          'last_played_date': today,
        });
      } else {
        final lastDate = existing['last_played_date'] as String?;
        final yesterday = DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String()
            .split('T')
            .first;
        final streak = lastDate == yesterday
            ? (existing['streak_days'] as int? ?? 0) + 1
            : (lastDate == today ? (existing['streak_days'] as int? ?? 1) : 1);

        await _db
            .from('couple_game_stats')
            .update({
              'games_together': (existing['games_together'] as int? ?? 0) + 1,
              'best_couple_score':
                  score > (existing['best_couple_score'] as int? ?? 0)
                  ? score
                  : existing['best_couple_score'],
              'streak_days': streak,
              'last_played_date': today,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', uid);
      }
    } catch (e) {
      debugPrint('recordCoupleGame error: $e');
    }
  }
}
