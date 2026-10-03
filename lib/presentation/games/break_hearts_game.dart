import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/game_service.dart';

/// Minijuego 5 — Rompe Corazones 💥❤️
/// Tap/swipe objects quickly, build combos
class BreakHeartsGame extends StatefulWidget {
  const BreakHeartsGame({super.key});
  @override
  State<BreakHeartsGame> createState() => _BreakHeartsGameState();
}

class _BreakHeartsGameState extends State<BreakHeartsGame>
    with TickerProviderStateMixin {
  static const String gameId = 'break_hearts';
  static const int gameDuration = 45;

  bool _isPlaying = false;
  bool _isFinished = false;
  int _score = 0;
  int _combo = 0;
  int _maxCombo = 0;
  int _timeLeft = gameDuration;
  int _bestScore = 0;
  int _coinsEarned = 0;

  Timer? _gameTimer;
  Timer? _spawnTimer;
  final List<_TapTarget> _targets = [];
  final Random _rng = Random();
  double _screenW = 300;
  double _screenH = 500;

  late AnimationController _comboAnim;

  static const List<Map<String, dynamic>> _types = [
    {'emoji': '❤️', 'pts': 10, 'bad': false},
    {'emoji': '💋', 'pts': 20, 'bad': false},
    {'emoji': '💕', 'pts': 30, 'bad': false},
    {'emoji': '💔', 'pts': -15, 'bad': true},
  ];

  @override
  void initState() {
    super.initState();
    _comboAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    final rec = await GameService.instance.getRecord(gameId);
    if (mounted) setState(() => _bestScore = rec?['best_score'] as int? ?? 0);
  }

  void _startGame() {
    setState(() {
      _score = 0;
      _combo = 0;
      _maxCombo = 0;
      _timeLeft = gameDuration;
      _isPlaying = true;
      _isFinished = false;
      _targets.clear();
      _coinsEarned = 0;
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        t.cancel();
        _endGame();
      }
    });

    _scheduleSpawn();
  }

  void _scheduleSpawn() {
    final delay = max(200, 800 - (_score * 3));
    _spawnTimer = Timer(Duration(milliseconds: delay), () {
      if (!_isPlaying || !mounted) return;
      _spawnTarget();
      _scheduleSpawn();
    });
  }

  void _spawnTarget() {
    final typeIdx = _rng.nextInt(10) < 2 ? 3 : _rng.nextInt(3);
    final type = _types[typeIdx];
    setState(() {
      _targets.add(
        _TapTarget(
          id: _rng.nextInt(999999),
          emoji: type['emoji'] as String,
          pts: type['pts'] as int,
          bad: type['bad'] as bool,
          x: 30 + _rng.nextDouble() * (_screenW - 80),
          y: 80 + _rng.nextDouble() * (_screenH - 160),
          life: 1.0,
        ),
      );
    });
  }

  void _tapTarget(_TapTarget t) {
    if (!_isPlaying) return;
    HapticFeedback.lightImpact();
    setState(() {
      _targets.removeWhere((o) => o.id == t.id);
      if (t.bad) {
        _score = max(0, _score + t.pts);
        _combo = 0;
      } else {
        _combo++;
        _maxCombo = max(_maxCombo, _combo);
        final mult = _combo >= 30
            ? 3
            : _combo >= 20
            ? 2
            : _combo >= 10
            ? 1
            : 1;
        _score += t.pts * mult;
      }
    });
    if (_combo >= 10) _comboAnim.forward(from: 0);
  }

  void _endGame() {
    _spawnTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _isFinished = true;
      _coinsEarned = _calcCoins(_score);
    });
    _saveResult();
  }

  int _calcCoins(int score) {
    if (score >= 400) return 30;
    if (score >= 200) return 20;
    if (score >= 80) return 14;
    return 10;
  }

  Future<void> _saveResult() async {
    final isRecord = _score > _bestScore;
    final bonus = isRecord ? 20 : 0;
    final total = _coinsEarned + bonus;
    await GameService.instance.addReward(
      coins: total,
      xp: total,
      gameId: gameId,
      score: _score,
    );
    await GameService.instance.completeChallenge('play_1');
    if (mounted) {
      setState(() {
        _coinsEarned = total;
        if (isRecord) _bestScore = _score;
      });
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _comboAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3E5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A1A1A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Rompe Corazones 💥❤️',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          if (_isPlaying)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '⏱ $_timeLeft s',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          _screenW = constraints.maxWidth;
          _screenH = constraints.maxHeight;
          return Stack(
            children: [
              if (_isPlaying) ...[
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Puntos: $_score',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Récord: $_bestScore',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ..._targets.map(
                  (t) => Positioned(
                    left: t.x,
                    top: t.y,
                    child: GestureDetector(
                      onTap: () => _tapTarget(t),
                      child: Text(
                        t.emoji,
                        style: const TextStyle(fontSize: 44),
                      ),
                    ),
                  ),
                ),
                if (_combo >= 10)
                  Positioned(
                    top: 80,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _comboAnim,
                        builder: (_, __) => Opacity(
                          opacity: 1 - _comboAnim.value,
                          child: Transform.scale(
                            scale: 1 + _comboAnim.value * 0.6,
                            child: Text(
                              _combo >= 30
                                  ? 'COMBO x$_combo 🔥🔥🔥'
                                  : _combo >= 20
                                  ? 'COMBO x$_combo 🔥🔥'
                                  : 'COMBO x$_combo 🔥',
                              style: GoogleFonts.dmSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF7B5EA7),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
              if (!_isPlaying) _isFinished ? _buildResult() : _buildStart(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStart() {
    return Container(
      color: const Color(0xFFF3E5F5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💥❤️', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            Text(
              'Rompe Corazones',
              style: GoogleFonts.dmSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca los objetos rápido\nEvita los 💔 · Construye combos',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: const Color(0xFF5A5A5A),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B5EA7),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                '¡Romper!',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final isRecord = _score >= _bestScore && _score > 0;
    return Container(
      color: const Color(0xFFF3E5F5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B5EA7).withAlpha(30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isRecord ? '🏆 ¡Nuevo Récord!' : '💥 ¡Bien hecho!',
                style: GoogleFonts.dmSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              _row('Puntuación', '$_score'),
              _row('Récord', '$_bestScore'),
              _row('Combo máximo', 'x$_maxCombo'),
              _row('LoveCoins ❤️', '+$_coinsEarned'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF7B5EA7)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Salir',
                        style: GoogleFonts.dmSans(
                          color: const Color(0xFF7B5EA7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B5EA7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Otra vez',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: const Color(0xFF5A5A5A),
          ),
        ),
        Text(
          v,
          style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _TapTarget {
  final int id;
  final String emoji;
  final int pts;
  final bool bad;
  final double x;
  final double y;
  double life;
  _TapTarget({
    required this.id,
    required this.emoji,
    required this.pts,
    required this.bad,
    required this.x,
    required this.y,
    required this.life,
  });
}
