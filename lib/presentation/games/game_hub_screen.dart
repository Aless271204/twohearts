import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/game_service.dart';
import '../../theme/app_theme.dart';
import './break_hearts_game.dart';
import './build_home_game.dart';
import './catch_kisses_game.dart';
import './couple_race_game.dart';
import './love_merge_game.dart';
import './perfect_date_game.dart';

/// Game Hub — shown inside Activities tab
/// Shows LoveCoins balance, 6 game cards, daily challenges, progression
class GameHubScreen extends StatefulWidget {
  const GameHubScreen({super.key});
  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _challenges = [];
  bool _loading = true;

  static const List<Map<String, dynamic>> _games = [
    {
      'id': 'catch_kisses',
      'title': 'Atrapa Besos',
      'emoji': '💋',
      'desc': 'Toca los besos y corazones\nEvita los 💔 · 30 segundos',
      'color': 0xFFFFD6E0,
      'textColor': 0xFFE8547A,
      'widget': CatchKissesGame,
    },
    {
      'id': 'perfect_date',
      'title': 'Cita Perfecta',
      'emoji': '🏃❤️',
      'desc': 'Corre y salta obstáculos\nRecoge corazones',
      'color': 0xFFB8E0CE,
      'textColor': 0xFF3D7A5E,
      'widget': PerfectDateGame,
    },
    {
      'id': 'build_home',
      'title': 'Construye el Hogar',
      'emoji': '🏠',
      'desc': 'Apila bloques perfectamente\nConstruye vuestra casa',
      'color': 0xFFFFE082,
      'textColor': 0xFFB45309,
      'widget': BuildOurHomeGame,
    },
    {
      'id': 'love_merge',
      'title': 'Love Merge',
      'emoji': '❤️💕',
      'desc': 'Combina corazones\n❤️+❤️=💕 · Estilo 2048',
      'color': 0xFFFFD6E0,
      'textColor': 0xFFE8547A,
      'widget': LoveMergeGame,
    },
    {
      'id': 'break_hearts',
      'title': 'Rompe Corazones',
      'emoji': '💥❤️',
      'desc': 'Toca rápido y construye combos\n45 segundos de adrenalina',
      'color': 0xFFE1BEE7,
      'textColor': 0xFF7B5EA7,
      'widget': BreakHeartsGame,
    },
    {
      'id': 'couple_race',
      'title': 'Carrera de Pareja',
      'emoji': '🏃‍♀️❤️🏃',
      'desc': 'Corran juntos, esquiven obstáculos\nRécord de pareja',
      'color': 0xFFBBDEFB,
      'textColor': 0xFF1565C0,
      'widget': CoupleRaceGame,
    },
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await GameService.instance.getStats();
    final challenges = await GameService.instance.getDailyChallenges();
    if (mounted) {
      setState(() {
        _stats = stats;
        _challenges = challenges;
        _loading = false;
      });
    }
  }

  Future<void> _openGame(Map<String, dynamic> game) async {
    final widgetType = game['widget'] as Type;
    Widget gameWidget;
    switch (widgetType) {
      case CatchKissesGame:
        gameWidget = const CatchKissesGame();
        break;
      case PerfectDateGame:
        gameWidget = const PerfectDateGame();
        break;
      case BuildOurHomeGame:
        gameWidget = const BuildOurHomeGame();
        break;
      case LoveMergeGame:
        gameWidget = const LoveMergeGame();
        break;
      case BreakHeartsGame:
        gameWidget = const BreakHeartsGame();
        break;
      default:
        gameWidget = const CoupleRaceGame();
        break;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => gameWidget),
    );
    // Refresh stats after returning
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final coins = _stats['love_coins'] as int? ?? 0;
    final xp = _stats['xp'] as int? ?? 0;
    final level = _stats['level'] as int? ?? 1;
    final levelName = GameService.instance.levelName(level);
    final xpNext = GameService.instance.xpForNextLevel(level);
    final xpPrev = level > 1
        ? GameService.instance.xpForNextLevel(level - 1)
        : 0;
    final xpProgress = xpNext > xpPrev
        ? (xp - xpPrev) / (xpNext - xpPrev)
        : 1.0;

    final completedChallenges = _challenges
        .where((c) => c['completed'] == true)
        .length;
    final allDone =
        completedChallenges == _challenges.length && _challenges.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          // ── Header ──────────────────────────────────────────────────────
          _buildHeader(coins, level, levelName, xp, xpNext, xpProgress),
          const SizedBox(height: 20),

          // ── Daily Challenges ────────────────────────────────────────────
          _buildChallengesSection(completedChallenges, allDone),
          const SizedBox(height: 20),

          // ── Games Grid ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '🎮 Minijuegos',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Juega y gana LoveCoins ❤️',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: const Color(0xFF9E9E9E),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: _games.length,
              itemBuilder: (ctx, i) => _buildGameCard(_games[i]),
            ),
          ),
          const SizedBox(height: 20),

          // ── Rewards info ────────────────────────────────────────────────
          _buildRewardsInfo(),
        ],
      ),
    );
  }

  Widget _buildHeader(
    int coins,
    int level,
    String levelName,
    int xp,
    int xpNext,
    double xpProgress,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFFFF7A9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎮', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                'Game Hub',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const Text('❤️', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      '$coins LoveCoins',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Nivel $level · $levelName',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withAlpha(220),
                ),
              ),
              const Spacer(),
              Text(
                '$xp / $xpNext XP',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: Colors.white.withAlpha(180),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: xpProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withAlpha(40),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesSection(int completed, bool allDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Retos de hoy ❤️',
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: allDone
                      ? AppTheme.secondaryContainer
                      : AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$completed/${_challenges.length}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: allDone ? AppTheme.secondary : AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                ..._challenges.map((c) => _buildChallengeRow(c)),
                if (allDone)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryContainer,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          '¡Todos los retos completados! +50 LoveCoins',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeRow(Map<String, dynamic> c) {
    final done = c['completed'] == true;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            done
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: done ? AppTheme.secondary : const Color(0xFFCCCCCC),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              c['challenge_label'] as String? ?? '',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: done ? const Color(0xFF9E9E9E) : const Color(0xFF1A1A1A),
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: done
                  ? AppTheme.secondaryContainer
                  : AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '+${c['reward_coins']} ❤️',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: done ? AppTheme.secondary : AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game) {
    final bgColor = Color(game['color'] as int);
    final textColor = Color(game['textColor'] as int);
    return GestureDetector(
      onTap: () => _openGame(game),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: bgColor.withAlpha(100),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(game['emoji'] as String, style: const TextStyle(fontSize: 36)),
            const Spacer(),
            Text(
              game['title'] as String,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              game['desc'] as String,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: textColor.withAlpha(180),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: textColor.withAlpha(20),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '¡Jugar!',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💰 Cómo ganar LoveCoins',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            _rewardRow('Partida normal', '+10 a +25 ❤️'),
            _rewardRow('Puntuación alta', '+25 a +40 ❤️'),
            _rewardRow('Nuevo récord', '+20 ❤️ extra'),
            _rewardRow('Reto diario', '+50 ❤️'),
            _rewardRow('Primera partida del día', '+20 ❤️'),
            _rewardRow('Victoria en pareja', '+30 ❤️'),
          ],
        ),
      ),
    );
  }

  Widget _rewardRow(String label, String reward) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: const Color(0xFF5A5A5A),
            ),
          ),
          Text(
            reward,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
