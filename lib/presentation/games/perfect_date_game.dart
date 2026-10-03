import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/game_service.dart';

/// Minijuego 2 — Cita Perfecta 🏃❤️
/// Infinite runner: tap to jump, collect hearts, avoid obstacles
class PerfectDateGame extends StatefulWidget {
  const PerfectDateGame({super.key});
  @override
  State<PerfectDateGame> createState() => _PerfectDateGameState();
}

class _PerfectDateGameState extends State<PerfectDateGame>
    with TickerProviderStateMixin {
  static const String gameId = 'perfect_date';

  // Game state
  bool _isPlaying = false;
  bool _isFinished = false;
  int _score = 0;
  int _distance = 0;
  int _bestScore = 0;
  int _coinsEarned = 0;

  // Character
  double _charY = 0; // 0 = ground
  double _velY = 0;
  bool _isJumping = false;
  static const double _gravity = 0.8;
  static const double _jumpForce = -14;
  static const double _groundY = 0;

  // Obstacles & collectibles
  final List<_RunnerObject> _objects = [];
  final Random _rng = Random();
  double _gameSpeed = 4;
  int _frameCount = 0;

  late AnimationController _runController;
  Timer? _gameTimer;

  @override
  void initState() {
    super.initState();
    _runController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 16),
          )
          ..addListener(_tick)
          ..repeat();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    final rec = await GameService.instance.getRecord(gameId);
    if (mounted) setState(() => _bestScore = rec?['best_score'] as int? ?? 0);
  }

  void _startGame() {
    setState(() {
      _score = 0;
      _distance = 0;
      _isPlaying = true;
      _isFinished = false;
      _charY = _groundY;
      _velY = 0;
      _isJumping = false;
      _objects.clear();
      _gameSpeed = 4;
      _frameCount = 0;
      _coinsEarned = 0;
    });
  }

  void _jump() {
    if (!_isPlaying) return;
    if (!_isJumping) {
      HapticFeedback.lightImpact();
      setState(() {
        _velY = _jumpForce;
        _isJumping = true;
      });
    }
  }

  void _tick() {
    if (!_isPlaying || !mounted) return;
    setState(() {
      _frameCount++;
      _distance = _frameCount ~/ 10;
      _score = _distance + (_score - _distance).clamp(0, 99999);

      // Physics
      _velY += _gravity;
      _charY += _velY;
      if (_charY >= _groundY) {
        _charY = _groundY;
        _velY = 0;
        _isJumping = false;
      }

      // Speed up
      _gameSpeed = 4 + _frameCount / 300;

      // Spawn objects
      if (_frameCount % max(40, 80 - _frameCount ~/ 100) == 0) {
        _spawnObject();
      }

      // Move objects
      for (final obj in _objects) {
        obj.x -= _gameSpeed;
      }
      _objects.removeWhere((o) => o.x < -60);

      // Collision detection
      for (final obj in _objects) {
        if (obj.x > 40 && obj.x < 100) {
          final charBottom = 200 + _charY;
          final charTop = charBottom - 50;
          final objTop = 200 - obj.height;
          final objBottom = 200.0;
          if (charBottom > objTop && charTop < objBottom) {
            if (obj.isObstacle) {
              _endGame();
              return;
            } else {
              _score += obj.points;
              obj.x = -999; // collect
            }
          }
        }
      }
    });
  }

  void _spawnObject() {
    final isObstacle = _rng.nextDouble() < 0.5;
    if (isObstacle) {
      final obstacles = ['🪨', '📦', '🛑', '💔'];
      _objects.add(
        _RunnerObject(
          emoji: obstacles[_rng.nextInt(obstacles.length)],
          x: 400,
          height: 40,
          isObstacle: true,
          points: 0,
        ),
      );
    } else {
      final collectibles = [
        {'emoji': '❤️', 'pts': 5},
        {'emoji': '💋', 'pts': 10},
        {'emoji': '💎', 'pts': 20},
      ];
      final c = collectibles[_rng.nextInt(collectibles.length)];
      _objects.add(
        _RunnerObject(
          emoji: c['emoji'] as String,
          x: 400,
          height: _rng.nextBool() ? 40 : 80, // ground or mid-air
          isObstacle: false,
          points: c['pts'] as int,
        ),
      );
    }
  }

  void _endGame() {
    setState(() {
      _isPlaying = false;
      _isFinished = true;
      _coinsEarned = _calcCoins(_score);
    });
    _saveResult();
  }

  int _calcCoins(int score) {
    if (score >= 300) return 30;
    if (score >= 150) return 20;
    if (score >= 50) return 14;
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
    _runController.dispose();
    _gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F5EE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A1A1A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cita Perfecta 🏃❤️',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: _isPlaying ? _jump : null,
        child: Stack(
          children: [
            // Sky gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFB8E0CE), Color(0xFFE8F5EE)],
                ),
              ),
            ),
            // Ground
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60,
                color: const Color(0xFF3D7A5E).withAlpha(80),
              ),
            ),
            // Score
            if (_isPlaying)
              Positioned(
                top: 16,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Distancia: $_distance m',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      'Récord: $_bestScore',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: const Color(0xFF5A5A5A),
                      ),
                    ),
                  ],
                ),
              ),
            // Character
            if (_isPlaying)
              Positioned(
                left: 60,
                bottom: 60 - _charY,
                child: const Text('🏃', style: TextStyle(fontSize: 40)),
              ),
            // Objects
            if (_isPlaying)
              ..._objects.map(
                (obj) => Positioned(
                  left: obj.x,
                  bottom: 60 + (obj.height == 80 ? 40 : 0),
                  child: Text(obj.emoji, style: const TextStyle(fontSize: 32)),
                ),
              ),
            // Tap hint
            if (_isPlaying)
              const Positioned(
                bottom: 80,
                right: 20,
                child: Text(
                  'Toca para saltar ☝️',
                  style: TextStyle(fontSize: 12, color: Color(0xFF5A5A5A)),
                ),
              ),
            // Overlays
            if (!_isPlaying) _isFinished ? _buildResult() : _buildStart(),
          ],
        ),
      ),
    );
  }

  Widget _buildStart() {
    return Container(
      color: const Color(0xFFE8F5EE),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏃❤️', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            Text(
              'Cita Perfecta',
              style: GoogleFonts.dmSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca para saltar\nRecoge corazones, evita obstáculos',
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
                backgroundColor: AppTheme.secondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                '¡Correr!',
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
      color: const Color(0xFFE8F5EE),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondary.withAlpha(40),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isRecord ? '🏆 ¡Nuevo Récord!' : '🎉 ¡Bien corrido!',
                style: GoogleFonts.dmSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              _row('Distancia', '$_distance m'),
              _row('Puntuación', '$_score'),
              _row('Récord', '$_bestScore'),
              _row('LoveCoins ❤️', '+$_coinsEarned'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.secondary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Salir',
                        style: GoogleFonts.dmSans(
                          color: AppTheme.secondary,
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
                        backgroundColor: AppTheme.secondary,
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

class _RunnerObject {
  final String emoji;
  double x;
  final double height;
  final bool isObstacle;
  final int points;
  _RunnerObject({
    required this.emoji,
    required this.x,
    required this.height,
    required this.isObstacle,
    required this.points,
  });
}
