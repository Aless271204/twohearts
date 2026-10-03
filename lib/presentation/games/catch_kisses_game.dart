import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/game_service.dart';

/// Minijuego 1 — Atrapa Besos 💋
/// Tap falling hearts/kisses, avoid broken hearts. 30 seconds.
class CatchKissesGame extends StatefulWidget {
  const CatchKissesGame({super.key});

  @override
  State<CatchKissesGame> createState() => _CatchKissesGameState();
}

class _CatchKissesGameState extends State<CatchKissesGame>
    with TickerProviderStateMixin {
  static const String gameId = 'catch_kisses';
  static const int gameDuration = 30;

  int _score = 0;
  int _combo = 0;
  int _maxCombo = 0;
  int _timeLeft = gameDuration;
  bool _isPlaying = false;
  bool _isFinished = false;
  int _bestScore = 0;
  int _coinsEarned = 0;

  Timer? _gameTimer;
  Timer? _spawnTimer;
  final List<_FallingObject> _objects = [];
  final Random _rng = Random();
  double _screenWidth = 300;
  double _screenHeight = 500;

  late AnimationController _comboController;

  static const List<Map<String, dynamic>> _objectTypes = [
    {'emoji': '💋', 'points': 10, 'type': 'kiss'},
    {'emoji': '❤️', 'points': 5, 'type': 'heart'},
    {'emoji': '💕', 'points': 20, 'type': 'double'},
    {'emoji': '💔', 'points': -10, 'type': 'broken'},
  ];

  @override
  void initState() {
    super.initState();
    _comboController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
      _objects.clear();
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
    final delay = max(300, 1200 - (_score * 5));
    _spawnTimer = Timer(Duration(milliseconds: delay), () {
      if (!_isPlaying || !mounted) return;
      _spawnObject();
      _scheduleSpawn();
    });
  }

  void _spawnObject() {
    final typeIdx = _rng.nextInt(10) < 2 ? 3 : _rng.nextInt(3);
    final type = _objectTypes[typeIdx];
    final x = _rng.nextDouble() * (_screenWidth - 50);
    setState(() {
      _objects.add(
        _FallingObject(
          id: _rng.nextInt(999999),
          emoji: type['emoji'] as String,
          points: type['points'] as int,
          x: x,
          y: -50,
          speed: 2.0 + _rng.nextDouble() * 2,
        ),
      );
    });
  }

  void _tapObject(_FallingObject obj) {
    if (!_isPlaying) return;
    HapticFeedback.lightImpact();
    setState(() {
      _objects.removeWhere((o) => o.id == obj.id);
      if (obj.points < 0) {
        _score = max(0, _score + obj.points);
        _combo = 0;
      } else {
        _combo++;
        _maxCombo = max(_maxCombo, _combo);
        final multiplier = _combo >= 15
            ? 4
            : _combo >= 7
            ? 3
            : _combo >= 3
            ? 2
            : 1;
        _score += obj.points * multiplier;
      }
    });
    if (_combo >= 3) {
      _comboController.forward(from: 0);
    }
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
    if (score >= 200) return 25;
    if (score >= 100) return 18;
    if (score >= 50) return 12;
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
    _comboController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF0F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A1A1A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Atrapa Besos 💋',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        actions: [
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
          _screenWidth = constraints.maxWidth;
          _screenHeight = constraints.maxHeight;
          return Stack(
            children: [
              // Score bar
              Positioned(top: 0, left: 0, right: 0, child: _buildScoreBar()),
              // Falling objects
              if (_isPlaying)
                ..._objects.map((obj) => _buildFallingObject(obj)),
              // Combo indicator
              if (_combo >= 3)
                Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _comboController,
                      builder: (_, __) => Opacity(
                        opacity: 1 - _comboController.value,
                        child: Transform.scale(
                          scale: 1 + _comboController.value * 0.5,
                          child: Text(
                            _combo >= 15
                                ? 'COMBO x4 🔥'
                                : _combo >= 7
                                ? 'COMBO x3 ⚡'
                                : 'COMBO x2 ✨',
                            style: GoogleFonts.dmSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Start / End overlay
              if (!_isPlaying)
                _isFinished ? _buildResultOverlay() : _buildStartOverlay(),
              // Tick objects down
              if (_isPlaying) _TickWidget(onTick: _tickObjects),
            ],
          );
        },
      ),
    );
  }

  void _tickObjects() {
    if (!_isPlaying || !mounted) return;
    setState(() {
      for (final obj in _objects) {
        obj.y += obj.speed;
      }
      _objects.removeWhere((o) => o.y > _screenHeight + 60);
    });
  }

  Widget _buildScoreBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Puntos: $_score',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: const Color(0xFF1A1A1A),
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
    );
  }

  Widget _buildFallingObject(_FallingObject obj) {
    return Positioned(
      left: obj.x,
      top: obj.y,
      child: GestureDetector(
        onTap: () => _tapObject(obj),
        child: Text(obj.emoji, style: const TextStyle(fontSize: 40)),
      ),
    );
  }

  Widget _buildStartOverlay() {
    return Container(
      color: const Color(0xFFFFF0F5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💋', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 16),
            Text(
              'Atrapa Besos',
              style: GoogleFonts.dmSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca los objetos positivos\nEvita los 💔',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: const Color(0xFF5A5A5A),
              ),
            ),
            const SizedBox(height: 8),
            _buildObjectLegend(),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                '¡Jugar!',
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

  Widget _buildObjectLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('💋', '+10'),
        const SizedBox(width: 12),
        _legendItem('❤️', '+5'),
        const SizedBox(width: 12),
        _legendItem('💕', '+20'),
        const SizedBox(width: 12),
        _legendItem('💔', '-10'),
      ],
    );
  }

  Widget _legendItem(String emoji, String pts) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        Text(
          pts,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5A5A5A),
          ),
        ),
      ],
    );
  }

  Widget _buildResultOverlay() {
    final isRecord = _score >= _bestScore && _score > 0;
    return Container(
      color: const Color(0xFFFFF0F5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withAlpha(30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isRecord ? '🏆 ¡Nuevo Récord!' : '🎉 ¡Bien hecho!',
                style: GoogleFonts.dmSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),
              _resultRow('Puntuación', '$_score'),
              _resultRow('Mejor puntuación', '$_bestScore'),
              _resultRow('Combo máximo', 'x$_maxCombo'),
              _resultRow('LoveCoins ❤️', '+$_coinsEarned'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Salir',
                        style: GoogleFonts.dmSans(
                          color: AppTheme.primary,
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
                        backgroundColor: AppTheme.primary,
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

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: const Color(0xFF5A5A5A),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}

class _FallingObject {
  final int id;
  final String emoji;
  final int points;
  final double x;
  double y;
  final double speed;
  _FallingObject({
    required this.id,
    required this.emoji,
    required this.points,
    required this.x,
    required this.y,
    required this.speed,
  });
}

class _TickWidget extends StatefulWidget {
  final VoidCallback onTick;
  const _TickWidget({required this.onTick});
  @override
  State<_TickWidget> createState() => _TickWidgetState();
}

class _TickWidgetState extends State<_TickWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 16),
          )
          ..addListener(widget.onTick)
          ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
